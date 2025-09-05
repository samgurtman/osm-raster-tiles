set -ex
sudo yum install -y java-21-amazon-corretto python3 git


curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs


sudo mkfs -t xfs /dev/nvme1n1
mkdir data
sudo mount /dev/nvme1n1 data

curl --fail -L https://download.geofabrik.de/north-america/us-latest.osm.pbf -o data/us-latest.osm.pbf
curl --fail -L https://github.com/onthegomap/planetiler/releases/download/v0.9.1/planetiler.jar -o planetiler.jar
java -Xmx12g -jar planetiler.jar --osm-path=$(pwd)/data/us-latest.osm.pbf --download --output data/us-vector.mbtiles
npm install -g tileserver-gl
tileserver-gl --silent &
python3 -m pip install -r requirements.txt
python3 generate.py -w 8 -s 256 -t data/temp -o data/tiles
output="data/$(date +"%Y-%m-%d").mbtiles"
mb-util data/tiles "$output"
aws s3 cp "$output" "s3://osm-freflight-raster/$output"
