import math
import os
import urllib.request 
import tempfile
import tqdm

from multiprocessing import Pool


def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 1 << zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
  return xtile, ytile
  
      
def render(tuple):
  temp_dir, output_dir, tile_size, zoom, x, y = tuple
  file_loc=f"{output_dir}/{zoom}/{x}/{y}.png"
  if os.path.isfile(file_loc):
    return
   
  os.makedirs(f"{output_dir}/{zoom}/{x}", exist_ok=True)
  url=f"http://localhost:8080/styles/foreflight/{tile_size}/{zoom}/{x}/{y}.png"
  temp = tempfile.NamedTemporaryFile(delete=False, dir=temp_dir)
  urllib.request.urlretrieve(url, temp.name)
  os.replace(temp.name, file_loc)
  return

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Download raster tiles')
    parser.add_argument('-w', '--workers', type=int, default=8, help='number of worker processes')
    parser.add_argument('-s', '--tile-size', type=int, default=256, help='tile size in pixels')
    parser.add_argument('-o', '--output-dir', type=str, default="tiles", help='output dir')
    parser.add_argument('-t', '--temp-dir', type=str, default="temp-tiles", help='temp dir')
    

    args = parser.parse_args()

    os.makedirs(args.temp_dir, exist_ok=true)

    tiles = []
    for zoom in range(0,16):
      start_x, start_y = deg2num(50, -125, zoom)
      end_x, end_y = deg2num(24, -66, zoom)
      for x in range(start_x, end_x + 1):
        for y in range(start_y, end_y + 1):
          tiles.append((args.temp_dir, args.output_dir, args.tile_size, zoom, x, y))

    with Pool(args.workers) as p:
        for result in tqdm.tqdm(p.imap_unordered(render, tiles, 200), total = len(tiles)):
          continue
