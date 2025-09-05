set -ex

portable_nproc() {
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        NPROCS="$(nproc --all)"
    elif [ "$OS" = "Darwin" ] || \
         [ "$(echo "$OS" | grep -q BSD)" = "BSD" ]; then
        NPROCS="$(sysctl -n hw.ncpu)"
    else
        NPROCS="$(getconf _NPROCESSORS_ONLN)"  # glibc/coreutils fallback
    fi
    echo "$NPROCS"
}


git submodule init
git submodule update
trap "killall node; rm -f config.json" EXIT


curl -L https://download.geofabrik.de/north-america/us-latest.osm.pbf -o data/us-latest.osm.pbf 
curl --fail -L https://github.com/onthegomap/planetiler/releases/download/v0.9.1/planetiler.jar -o planetiler.jar
java -Xmx32g -jar planetiler.jar --osm-path=$(pwd)/data/us-latest.osm.pbf --download --output data/us-vector.mbtiles

NPROC=$(portable_nproc)
export NPROC
envsubst < config.json.tmpl > config.json
npx tileserver-gl --silent &
sleep 10
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements.txt
output="$(date +"%Y-%m-%d").mbtiles"
python3 generate.py --workers "$NPROC" --output "$output" --image-type "png" --tile-size 256 --max-zoom 15
