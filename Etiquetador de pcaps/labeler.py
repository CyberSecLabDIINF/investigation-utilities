import argparse
import sys

import pandas as pd
from pandas import DataFrame

parser = argparse.ArgumentParser()

if __name__ == "__main__":
    parser.add_argument("-f", "--file", type=str, required=True, help="Path to the CSV file")
    parser.add_argument(
        "-l", "--label",
        type=str,
        choices=["malicious", "benign"],
        required=True,
        help="El label debe ser 'malicious' o 'benign'."
    )
    parser.add_argument("-c", "--category", type=str)
    parser.add_argument("-t", "--type", type=str)

    args = parser.parse_args()

    if args.label == "benign":
        args.category = "benign"
        args.type = "benign"
        print("Se etiqueto el archivo como 'benign', 'category' y 'type' se ignorarán.")
    elif args.label == "malicious":
        if args.category is None or args.type is None:
            print("Para etiquetar un archivo como 'malicious', se debe especificar 'category' y 'type'.")
            sys.exit(1)

    data_frame: DataFrame = pd.read_csv(args.file)
    data_frame["Label"] = args.label
    data_frame["Category"] = args.category
    data_frame["Type"] = args.type

    filename_output = args.file + "_labeled.csv"
    csv_output = data_frame.to_csv(filename_output, index=False)

    print("File saved as:", filename_output)



