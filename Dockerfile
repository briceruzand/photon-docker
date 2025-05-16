######################################################################
# BUILD
######################################################################
FROM eclipse-temurin:21-jdk-noble AS build

RUN apt-get update \  
  && apt-get -y install --no-install-recommends \
  git \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /build/
WORKDIR /build/
RUN git clone https://github.com/komoot/photon.git

WORKDIR /build/photon
RUN ./gradlew dependencies --no-daemon
RUN mkdir -p /build/photon/patches/
COPY ./patches/ ./patches/
RUN git apply patches/*.patch
RUN ./gradlew clean build -x test --no-daemon
RUN cp -a target/photon-0.6.*.jar target/photon.jar

######################################################################
# RUNTIME
######################################################################
FROM eclipse-temurin:21-jre-noble AS runtime

RUN apt-get update \  
  && apt-get -y install --no-install-recommends \
  pbzip2 \
  wget \
  procps \
  coreutils \
  tree \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /photon

RUN mkdir -p /photon/photon_data

COPY --from=build /build/photon/target/photon.jar /photon/photon.jar

COPY start-photon.sh ./start-photon.sh
COPY src/ ./src/
RUN chmod +x start-photon.sh src/*.sh


VOLUME /photon/photon_data
EXPOSE 2322

ENTRYPOINT ["/photon/start-photon.sh"]

