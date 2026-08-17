import random
import sys

# gen_input_vector nb_data nb_count

# Parameters from command line
NB_COUNT = 8 if len(sys.argv) == 2 else int(sys.argv[2])
NB_DATA  = 8 if len(sys.argv) == 1 else int(sys.argv[1])

MAX_DATA_VAL    = (2**NB_DATA) - 1
MAX_COUNT_VAL   = (2**NB_COUNT) - 1
VECTOR_PATH     = '../tb/vectors'



# Parameters
FILENAME        = f'{VECTOR_PATH}/vector_ovf_nb_data_{NB_DATA}_nb_count_{NB_COUNT}.txt'
NUM_SEQUENCES  = 50            # Number of times it will alternate between runs or literals
MAX_RUN_LENGTH = MAX_COUNT_VAL # Maximum length of a repeated data
MAX_LIT_LENGTH = MAX_COUNT_VAL # Maximum length of a literal sequence

def generate_test_file():
    with open(FILENAME, "w") as f:
        for i in range(NUM_SEQUENCES):

            is_run = random.choice([True, False])
            
            if is_run:
                # --- RUN MODE ---
                length = MAX_RUN_LENGTH
                byte_val = random.randint(0, MAX_DATA_VAL)
                line_str  = f"{byte_val:02X}\n"
                f.write(line_str * length)

            else:
                # --- LITERAL MODE ---
                length = MAX_LIT_LENGTH
                prev_byte = -1
                lines = []
                
                for _ in range(length):
                    byte_val = random.randint(0, MAX_DATA_VAL)
                    while byte_val == prev_byte:
                        byte_val = random.randint(0, MAX_DATA_VAL)

                    lines.append(f"{byte_val:02X}\n")
                    prev_byte = byte_val
                f.write(''.join(lines))

    print(f"==================================================")
    print(f" File '{FILENAME}' successfully generated.")
    print(f"==================================================")

if __name__ == "__main__":
    generate_test_file()