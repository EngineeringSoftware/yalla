To generate the paper's results, run:
```bash
./run.sh setup_all
./run.sh run_all
```
The `setup_all` process takes around 40 mins and `run_all` takes
around 30 mins depending on your machine.

All results will be generated in the `results/` directory. All
compilation time results are in CSV files that start with
`compilation`. There is a separate CSV file per mode, i.e. normal,
PCH, and Yalla, and there are two sets of files, one for the PyKokkos
subjects (`compilation\_kokkos`) and one for the benchmarks
(`compilation\_other`). The running times for the PyKokkos subjects
can be found in `kernels` CSV files for individual kernels and `total`
CSV files for the total Python application running time. The running
times for the other subjects are in the compilation CSV files. The
`stats` CSV files shows LOC and header file statistics.

The trace of compilation (corresponding to Fig 7 in the paper) is under
`results/trace/`. You can use Chrome to view the trace file by opening
`chrome://tracing` and loading the trace file.

## Docker

To run it in a docker container, you can use the following commands:
```bash
docker build -t yalla-cgo-ae .

# For interactive mode
docker run -it yalla-cgo-ae:latest /bin/bash
./run.sh setup_all
./run.sh run_all

# For detached mode
docker run -d yalla-cgo-ae:latest ./run.sh setup_all
docker run -d yalla-cgo-ae:latest ./run.sh run_all
```

You can copy the results to your host and view them in your favorite editor with:
```bash
docker cp <containerId>:/file/path/within/container /host/path/target
```

Remove the image and container when you are done:
```bash
# You can run `docker rmi` or `docker ps -a` first to get the container_id
docker rm <containerId>
docker rmi yalla-cgo-ae:latest
```
