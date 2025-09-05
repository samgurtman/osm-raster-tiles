set -ex

trap "shutdown now" EXIT

wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list

sudo apt-get update
sudo apt-get install -y java-21-amazon-corretto-jdk libbz2-dev libjpeg-turbo8 libglx-dev python3 curl libopengl-dev
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo apt-get install -y nodejs


sudo mkfs -t xfs /dev/nvme1n1
mkdir data
sudo mount /dev/nvme1n1 data
sudo chown -R ubuntu data
curl -L https://download.geofabrik.de/north-america/us-latest.osm.pbf -o data/us-latest.osm.pbf 
curl --fail -L https://github.com/onthegomap/planetiler/releases/download/v0.9.1/planetiler.jar -o planetiler.jar

java -Xmx32g -jar planetiler.jar --osm-path=$(pwd)/data/us-latest.osm.pbf --download --output data/us-vector.mbtiles
sudo npm install -g tileserver-gl
tileserver-gl --silent &
python3 -m pip install -r requirements.txt
python3 generate.py -w 8 -s 256 -t data/temp -o data/tiles -b "$bounds"
output="data/$(date +"%Y-%m-%d").mbtiles"
mb-util data/tiles "$output"
aws s3 cp "$output" "s3://osm-freflight-raster/$output"

