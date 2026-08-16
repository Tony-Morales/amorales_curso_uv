#!/bin/bash

rm -rf ../tb/vectors

mkdir ../tb/vectors

# NB_DATA = 8 NB_COUNT = 8
python3 gen_random_vector.py    8 8
python3 gen_overflow_vector.py  8 8

# NB_DATA = 16 NB_COUNT = 8
python3 gen_random_vector.py    16 8
python3 gen_overflow_vector.py  16 8

# NB_DATA = 16 NB_COUNT = 16
python3 gen_random_vector.py    16 16
python3 gen_overflow_vector.py  16 16

# NB_DATA = 32 NB_COUNT = 8
python3 gen_random_vector.py    32 8
python3 gen_overflow_vector.py  32 8

# NB_DATA = 32 NB_COUNT = 16
python3 gen_random_vector.py    32 16
python3 gen_overflow_vector.py  32 16

#Vectors from img
python3 gen_img_vector.py hand_rx.jpg
python3 gen_img_vector.py hand_rx.jpg true

python3 gen_img_vector.py hand_rx_2.jpg
python3 gen_img_vector.py hand_rx_2.jpg true

python3 gen_img_vector.py knee_rx.jpg
python3 gen_img_vector.py knee_rx.jpg true
