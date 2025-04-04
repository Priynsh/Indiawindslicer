# Wind Data Visualizer

This web-based visualizer was built using Julia, Bonito, and WGLMakie to explore wind data over India. The application reads gridded wind layer data from CSV files and provides an interactive interface for slicing and visualizing wind speed data at different altitudes.

## Data Source

The wind data used in this project is obtained from [Global Wind Atlas](https://globalwindatlas.info/).

## Scope of Data

Due to the large download size of the full dataset, **this project currently includes wind data only for India**.

## Available Heights

Wind data is available for the following heights above ground level:

- 10 meters
- 50 meters
- 100 meters
- 150 meters
- 200 meters

## Interactive Features

- A height **slider** is provided in the interface to slice the data by height.
- When the slider is adjusted, the plot updates in real time to reflect the wind data at the selected height.
## Demo
  ![Demo](https://github.com/Priynsh/Indiawindslicer/blob/main/indiatemp.gif)
## Usage

To run the server locally:

```julia
julia> include("main.jl")  # or the relevant file name containing the server code
```

Make sure all required dependencies are installed and the CSV files for the respective heights (named as `binned_data_10m.csv`, `binned_data_50m.csv`, etc.) are present in the working directory.

---

