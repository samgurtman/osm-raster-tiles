import math
import os
import urllib.request 
import tempfile
import tqdm

from multiprocessing.pool import ThreadPool
from pymbtiles import MBtiles, Tile


def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 1 << zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
  return xtile, ytile
  
      


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Download raster tiles')
    parser.add_argument('-w', '--workers', type=int, default=8, help='number of worker processes')
    parser.add_argument('-s', '--tile-size', type=int, default=256, help='tile size in pixels')
    parser.add_argument('-o', '--output', type=str, help='output file')
    parser.add_argument('-i', '--image-type', type=str, help='Image Type')
    parser.add_argument('-m', '--max-zoom', type=int, default=15, help='Max Zoom')



    args = parser.parse_args()


    def render(tuple):
      zoom, x, y = tuple
      # file_loc=f"{output_dir}/{zoom}/{x}/{y}.png"
      # if os.path.isfile(file_loc):
      
      # os.makedirs(f"{output_dir}/{zoom}/{x}", exist_ok=True)
      url=f"http://localhost:8080/styles/foreflight/{args.tile_size}/{zoom}/{x}/{y}.{args.image_type}"
      # temp = tempfile.NamedTemporaryFile(delete=False, dir=temp_dir)
      # urllib.request.urlretrieve(url, temp.name)
      # os.replace(temp.name, file_loc)
      with urllib.request.urlopen(url) as response:
        # Read the entire response body as bytes
        return (zoom, x, y, response.read())
      
    tiles = []
    for zoom in range(0,args.max_zoom + 1):
      start_x, start_y = deg2num(50, -125, zoom)
      end_x, end_y = deg2num(24, -66, zoom)
      for x in range(start_x, end_x + 1):
        for y in range(start_y, end_y + 1):
          tiles.append((zoom, x, y))

    with MBtiles(args.output, 'w') as mbtiles:
      mbtiles.meta['name'] = 'OSM ForeFlight'
      mbtiles.meta['type'] = 'baselayer'
      mbtiles.meta['version'] = '1'
      mbtiles.meta['description'] = 'OSM Rendered in OSM Liberty Style without Runways or Taxiways'
      mbtiles.meta['format'] = args.image_type
      mbtiles.meta['bounds'] = '-125,24,-66,50'
      with ThreadPool(args.workers) as p:
          for result in tqdm.tqdm(p.imap_unordered(render, tiles, 200), total = len(tiles)):
            zoom, x, y, tile_bytes = result
            xyz_y = (2 ** zoom) - y - 1

            mbtiles.write_tile(z = zoom, x = x, y = xyz_y, data = tile_bytes)
