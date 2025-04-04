using ArchGDAL, DataFrames, StatsBase, CSV

# Load the .tif file
function load_tif(filename)
    ArchGDAL.read(filename) do dataset
        band = ArchGDAL.getband(dataset, 1)  # Assuming single-band
        array = ArchGDAL.read(band)  # Get raster values as an array
        geo_transform = ArchGDAL.getgeotransform(dataset)  # Get transform for X, Y
        return array, geo_transform
    end
end

# Convert raster indices to real-world X, Y coordinates
function get_coordinates(array, geo_transform)
    nx, ny = size(array)
    X = [geo_transform[1] + (i-1) * geo_transform[2] for i in 1:nx]
    Y = [geo_transform[4] + (j-1) * geo_transform[6] for j in 1:ny]
    return X, Y
end

# Bin data by rounding X and Y to the nearest 0.5
function bin_data(array, X, Y)
    df = DataFrame(X=repeat(X, length(Y)), Y=repeat(Y, inner=length(X)), Layer1=vec(array))
    
    # Round X and Y to nearest 0.5 interval
    df.X = round.(df.X ./ 0.5) .* 0.5  
    df.Y = round.(df.Y ./ 0.5) .* 0.5  
    
    # Aggregate values within each bin (e.g., using mean)
    binned_df = combine(groupby(df, [:X, :Y]), :Layer1 => mean => :Layer1)
    
    # Remove NaN values
    filter!(:Layer1 => x -> !isnan(x), binned_df)
    
    return binned_df
end

# Save DataFrame to CSV
function save_to_csv(df, output_filename)
    CSV.write(output_filename, df)
    println("Saved binned data to $output_filename")
end

# Example Usage
filename = "IND_wind-speed_200m.tif"  # Update with your file path
output_csv = "binned_data_200m.csv"

array, geo_transform = load_tif(filename)
X, Y = get_coordinates(array, geo_transform)
binned_df = bin_data(array, X, Y)
save_to_csv(binned_df, output_csv)
