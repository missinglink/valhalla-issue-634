# base image
FROM ubuntu:16.04

# -- dependencies --
RUN apt-get update && apt-get install -y software-properties-common python-software-properties wget

# -- configure locale --
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# -- install valhalla --
# grab all of the valhalla software from ppa
RUN add-apt-repository -y ppa:kevinkreiser/prime-server
RUN add-apt-repository -y ppa:valhalla-routing/valhalla
RUN apt-get update
RUN apt-get install -y valhalla-bin

# -- directories --
RUN mkdir -p /data/tiles
ENV TILESPATH /data/tiles

# -- generate config --
RUN valhalla_build_config \
  --mjolnir-tile-dir "$TILESPATH" \
  --mjolnir-tile-extract "$TILESPATH.tar" \
  --mjolnir-timezone "$TILESPATH/timezones.sqlite" \
  --mjolnir-admin "$TILESPATH/admins.sqlite" > /data/valhalla.json

# -- download data --
WORKDIR /data
RUN wget 'http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf';
ENV PBFFILE /data/berlin-latest.osm.pbf

# -- build routing tiles --
RUN valhalla_build_tiles -c /data/valhalla.json "$PBFFILE"

# -- run server --
# CMD valhalla_route_service valhalla.json 1
CMD ["valhalla_route_service", "/data/valhalla.json", "1"]
