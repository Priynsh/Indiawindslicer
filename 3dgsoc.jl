using Bonito, WGLMakie, LinearAlgebra
import Bonito.TailwindDashboard as D
using WGLMakie, DataFrames, CSV, ColorSchemes, Images, FileIO, Makie
const INDIA_MIN_LON = 68.0
const INDIA_MAX_LON = 97.0
const INDIA_MIN_LAT = 8.0
const INDIA_MAX_LAT = 37.0


mask_img = load("output.jpg")
mask = Float32.(Gray.(mask_img) .< 0.5)

grid_size = 800
x_grid = range(0, 800, length=grid_size)
y_grid = range(0, 800, length=grid_size)
temp_cmap = cgrad([:blue, :lightblue, :green, :yellow, :orange, :red], 
                 [0.0, 0.2, 0.4, 0.6, 0.8, 1.0])

function find_nearest_temp(x, y, points, temps)
    min_dist1, min_dist2, min_dist3 = Inf, Inf, Inf
    temp1, temp2, temp3 = missing, missing, missing
    for i in 1:size(points, 2)
        dist = sqrt((x - points[1, i])^2 + (y - points[2, i])^2)
        if dist < min_dist1
            min_dist3, temp3 = min_dist2, temp2
            min_dist2, temp2 = min_dist1, temp1
            min_dist1, temp1 = dist, temps[i]
        elseif dist < min_dist2
            # Shift the second nearest
            min_dist3, temp3 = min_dist2, temp2
            min_dist2, temp2 = dist, temps[i]
        elseif dist < min_dist3
            min_dist3, temp3 = dist, temps[i]
        end
    end

    return (temp1+ temp2+ temp3)/3
end

function temp_slicer()
    App() do session::Session
        h_slice = Bonito.Slider(1:5, value=1)
        values = [10, 50, 100, 150, 200]
        lat_slice = Bonito.Slider(8:0.5:37, value=16)
        long_slice = Bonito.Slider(68:0.5:97, value=80)
        y_position = @lift(($lat_slice - 8) * (800)/ (37 - 8))
        x_position = @lift(($long_slice - 68) * (800)/ (97 - 68))
        fig = Figure(size=(650, 750))
        fig.layout[1, 1] = GridLayout(height = Relative(0.85))  # Main heatmap gets 85% of height
        fig.layout[2, 1] = GridLayout(height = Relative(0.15))  # Slice plot gets 15%
        ax = WGLMakie.Axis(fig[1, 1], title="Wind speeds")
        heatmap_obj = heatmap!(ax, x_grid, y_grid, zeros(grid_size, grid_size), 
                               colormap=temp_cmap, nan_color=:white)
        lineploty = lines!(ax, 1:800, @lift(fill($y_position, 800)); color=:black, linewidth=1)
        lineplotx = lines!(ax, @lift(fill($x_position, 800)), 1:800 ; color=:black, linewidth=1)
        ax_slice = WGLMakie.Axis(fig[2, 1], title="Temperature Slice at Lat/Long", height=100)
        grid_values_ref  =  Ref(zeros(grid_size, grid_size))
        slice_plot = lines!(ax_slice, x_grid, zeros(grid_size); color=:red)
        slice_plot2 = lines!(ax_slice, y_grid,zeros(grid_size); color=:blue)
        function update_plot(selected_height_index)
            height = values[selected_height_index]
            filepath = "binned_data_$(height)m.csv"
            cities_locations = CSV.read(filepath, DataFrame) |>
                df -> select(df, [:Layer1, :X, :Y])
            cities_locations.x_px = 800 .* (cities_locations.X .- INDIA_MIN_LON) ./ (INDIA_MAX_LON - INDIA_MIN_LON)
            cities_locations.y_px = 800 .* ((cities_locations.Y .- INDIA_MIN_LAT) ./ (INDIA_MAX_LAT - INDIA_MIN_LAT))
            points = hcat(cities_locations.x_px, cities_locations.y_px)'
            temps = cities_locations.Layer1

            grid_values = [find_nearest_temp(x, y, points, temps) for x in x_grid, y in y_grid]
            grid_values = Float32.(grid_values)
            masked_values = grid_values .* mask
            masked_values[masked_values .== 0] .= NaN
            grid_values_ref[] = masked_values
            heatmap_obj[3] = masked_values
            update_slice_plot()
            update_slice_plot2()
        end
        function update_slice_plot()
            row = y_position[]
            row = round(Int, row)
            row = grid_size - row + 1
            if 1 <= row <= grid_size
                println("Row: ", row)
                slice_data = grid_values_ref[][row, :]
                slice_plot[2] = slice_data
            end
        end
        function update_slice_plot2()
            col= x_position[]
            col= round(Int, col)
            if 1 <= col <= grid_size
                slice_data = grid_values_ref[][:, col]
                slice_plot2[2] = reverse(slice_data)
            end
        end
        update_plot(1)
        on(h_slice.value) do v
            update_plot(v)
        end
        on(lat_slice.value) do _
            update_slice_plot()
        end
        on(long_slice.value) do _
            update_slice_plot2()
        end
        value = map(h_slice.value) do x
            return values[x]
        end
        sliders = DOM.div(
            DOM.div("Elevation: ", h_slice,value," Meters"),
            DOM.div("Latitude: ", lat_slice,lat_slice.value," Degrees"),
            DOM.div("Longitude: ", long_slice,long_slice.value, " Degrees"),
        )
        DOM.div(
            fig,sliders
        )
    end
end

function start_server()
    app = temp_slicer()
    Bonito.Server(app, "0.0.0.0", 8000)
end

start_server()
