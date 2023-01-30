#!/bin/bash -v
#
# will expand to ./data
#
curl -SL http://www.meteo.physik.uni-muenchen.de/~libradtran/lib/exe/fetch.php?media=download:reptran_2017_all.tar.gz | tar -xzC .
