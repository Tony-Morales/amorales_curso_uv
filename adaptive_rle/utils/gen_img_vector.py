from PIL import Image
import numpy as np
import sys

# gen_vector_from_img img_name

IMAGE_NAME = sys.argv[1]
RESIZE     = len(sys.argv) == 3 and  sys.argv[2]== 'true'
FILENAME   = f'../tb/vectors/vector_{IMAGE_NAME[:-4]}_{"resize" if RESIZE else 'fullsize'}.txt'

def img_to_txt():
    if RESIZE:
        img = Image.open(IMAGE_NAME).convert('L').resize((128, 128))
    else:
        img = Image.open(IMAGE_NAME).convert('L')

    pixels = np.array(img).flatten()

    with open(FILENAME  , "w") as f:
        for pixel in pixels:
            f.write(f"{pixel:02X}\n")

    print(f"==================================================")
    print(f" File '{FILENAME}' successfully generated.")
    print(f"==================================================")

if __name__ == "__main__":
    img_to_txt()