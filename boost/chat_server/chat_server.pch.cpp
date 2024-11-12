//
// chat_server.cpp
// ~~~~~~~~~~~~~~~
//
// Copyright (c) 2003-2024 Christopher M. Kohlhoff (chris at kohlhoff dot com)
//
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
#include "asio-all.h"
#include <cstdlib>
#include <deque>
#include <iostream>
#include <list>
#include <memory>
#include <set>
#include <utility>
#include "chat_message.hpp"

using boost::asio::ip::tcp;

//----------------------------------------------------------------------

typedef std::deque<chat_message> chat_message_queue;

//----------------------------------------------------------------------

class chat_participant
{
public:
  virtual ~chat_participant() {}
  virtual void deliver(const chat_message& msg) = 0;
};

typedef std::shared_ptr<chat_participant> chat_participant_ptr;

//----------------------------------------------------------------------

class chat_room
{
public:
  void join(chat_participant_ptr participant)
  {
    participants_.insert(participant);
    for (auto msg: recent_msgs_)
      participant->deliver(msg);
  }

  void leave(chat_participant_ptr participant)
  {
    participants_.erase(participant);
  }

  void deliver(const chat_message& msg)
  {
    recent_msgs_.push_back(msg);
    while (recent_msgs_.size() > max_recent_msgs)
      recent_msgs_.pop_front();

    for (auto participant: participants_)
      participant->deliver(msg);
  }

private:
  std::set<chat_participant_ptr> participants_;
  enum { max_recent_msgs = 100 };
  chat_message_queue recent_msgs_;
};

//----------------------------------------------------------------------

class chat_session
  : public chat_participant,
    public std::enable_shared_from_this<chat_session>
{
public:
  friend class do_write_functor;
  friend class do_read_header_functor;
  friend class do_read_body_functor;

  chat_session(tcp::socket socket, chat_room& room)
    : socket_(std::move(socket)),
      room_(room)
  {
  }

  void start()
  {
    room_.join(shared_from_this());
    do_read_header();
  }

  void deliver(const chat_message& msg)
  {
    bool write_in_progress = !write_msgs_.empty();
    write_msgs_.push_back(msg);
    if (!write_in_progress)
    {
      do_write();
    }
  }

private:

  struct do_read_header_functor {
    do_read_header_functor(chat_session* this_ptr, std::shared_ptr<chat_session> self)
     : this_ptr(this_ptr), self(self) {}

    void operator()(boost::system::error_code ec, unsigned int /*length*/) const {
          if (!ec && this_ptr->read_msg_.decode_header())
          {
            this_ptr->do_read_body();
          }
          else
          {
            this_ptr->room_.leave(this_ptr->shared_from_this());
          }
    }

    chat_session* this_ptr;
    std::shared_ptr<chat_session> self;
  };

  void do_read_header()
  {
    auto self(shared_from_this());
    // boost::asio::async_read(socket_,
    //     boost::asio::buffer(read_msg_.data(), chat_message::header_length),
    //     [this, self](boost::system::error_code ec, unsigned int /*length*/)
    //     {
    //       if (!ec && read_msg_.decode_header())
    //       {
    //         do_read_body();
    //       }
    //       else
    //       {
    //         room_.leave(shared_from_this());
    //       }
    //     });
    do_read_header_functor f(this, self);

    boost::asio::async_read(socket_,
        boost::asio::buffer(read_msg_.data(), chat_message::header_length), f);
  }

  struct do_read_body_functor {
    do_read_body_functor(chat_session* this_ptr, std::shared_ptr<chat_session> self)
     : this_ptr(this_ptr), self(self) {}

    void operator()(boost::system::error_code ec, unsigned int /*length*/) const {
          if (!ec)
          {
            this_ptr->room_.deliver(this_ptr->read_msg_);
            this_ptr->do_read_header();
          }
          else
          {
            this_ptr->room_.leave(this_ptr->shared_from_this());
          }
    }

    chat_session* this_ptr;
    std::shared_ptr<chat_session> self;
  };

  void do_read_body()
  {
    auto self(shared_from_this());
    // boost::asio::async_read(socket_,
    //     boost::asio::buffer(read_msg_.body(), read_msg_.body_length()),
    //     [this, self](boost::system::error_code ec, unsigned int /*length*/)
    //     {
    //       if (!ec)
    //       {
    //         room_.deliver(read_msg_);
    //         do_read_header();
    //       }
    //       else
    //       {
    //         room_.leave(shared_from_this());
    //       }
    //     });

    do_read_body_functor f(this, self);
    boost::asio::async_read(socket_,
            boost::asio::buffer(read_msg_.body(), read_msg_.body_length()), f);
  }

  struct do_write_functor {
    do_write_functor(chat_session* this_ptr, std::shared_ptr<chat_session> self)
     : this_ptr(this_ptr), self(self) {}

    void operator()(boost::system::error_code ec, unsigned int /*length*/) const {
          if (!ec)
          {
            this_ptr->room_.deliver(this_ptr->read_msg_);
            this_ptr->do_read_header();
          }
          else
          {
            this_ptr->room_.leave(this_ptr->shared_from_this());
          }
    }

    chat_session* this_ptr;
    std::shared_ptr<chat_session> self;
  };

  void do_write()
  {
    auto self(shared_from_this());
    // boost::asio::async_write(socket_,
    //     boost::asio::buffer(write_msgs_.front().data(),
    //       write_msgs_.front().length()),
    //     [this, self](boost::system::error_code ec, unsigned int /*length*/)
    //     {
    //       if (!ec)
    //       {
    //         write_msgs_.pop_front();
    //         if (!write_msgs_.empty())
    //         {
    //           do_write();
    //         }
    //       }
    //       else
    //       {
    //         room_.leave(shared_from_this());
    //       }
    //     });

    do_write_functor f(this, self);
    auto buffer_temp = boost::asio::buffer(write_msgs_.front().data(),
              write_msgs_.front().length());
    boost::asio::async_write(socket_,
            buffer_temp, f);
  }

  tcp::socket socket_;
  chat_room& room_;
  chat_message read_msg_;
  chat_message_queue write_msgs_;
};

//----------------------------------------------------------------------



class chat_server
{
public:
  chat_server(boost::asio::io_context& io_context,
      const tcp::endpoint& endpoint)
    : acceptor_(io_context, endpoint)
  {
    do_accept();
  }

private:
  void do_accept()
  {
    // acceptor_.async_accept(
    //     [this](boost::system::error_code ec, tcp::socket socket)
    //     {
    //       if (!ec)
    //       {
    //         std::make_shared<chat_session>(std::move(socket), room_)->start();
    //       }

    //       do_accept();
    //     });
  }

  tcp::acceptor acceptor_;
  chat_room room_;
};

//----------------------------------------------------------------------

int main(int argc, char* argv[])
{
  try
  {
    if (argc < 2)
    {
      std::cerr << "Usage: chat_server <port> [<port> ...]\n";
      return 1;
    }

    boost::asio::io_context io_context;

    std::list<chat_server*> servers;
    for (int i = 1; i < argc; ++i)
    {
      tcp temp = tcp::v4();
      tcp::endpoint endpoint(temp, std::atoi(argv[i]));
      chat_server* temp2 = new chat_server(io_context, endpoint);
      // servers.emplace_back(io_context, endpoint);
      servers.push_back(temp2);
    }

    io_context.run();
  }
  catch (std::exception& e)
  {
    std::cerr << "Exception: " << e.what() << "\n";
  }

  return 0;
}
