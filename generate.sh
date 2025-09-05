sudo yum install -y curl java-21-amazon-corretto python3 git


curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs

cd /opt/osm-raster-tiles

mkdir data
curl --fail -L https://download.geofabrik.de/north-america/us-latest.osm.pbf -o data/us-latest.osm.pbf
curl --fail -L https://github.com/onthegomap/planetiler/releases/download/v0.9.1/planetiler.jar -o planetiler.jar
java -Xmx12g -jar planetiler.jar --osm-path=$(pwd)/data/us-latest.osm.pbf --download --output data/us-vector.mbtiles
npm install -g tileserver-gl
tileserver-gl --silent &
python3 -m pip install -r requirements.txt
python3 generate.py -w 8 -s 256
output="$(date +"%Y-%m-%d").mbtiles"
mb-util tiles-256 "$output"
aws s3 cp "$output" "s3://osm-freflight-raster/$output"
