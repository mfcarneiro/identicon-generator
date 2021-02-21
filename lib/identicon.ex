defmodule Identicon do
  @number_of_rows 5
  @square_size 50
  @grid_size 250

  def main(input),
    do:
      input
      |> hash_input
      |> pick_color
      |> build_grid
      |> filter_odd_squares
      |> build_pixel_map
      |> draw_image
      |> save_image(input)

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      # This syntax is used to pass a funciton as reference
      # the /1 indicates that you want that function to only has one argument, if invoked or have more arguments available
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      # By design, Elixir do not present an index when working with lists
      # So, Enum.with_index is called to add the index in each row of the line, in a tuble
      # e.q: [{0,0}, {1,1}, {2,2}...]
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_code, index} ->
        horizontal = rem(index, @number_of_rows) * @square_size
        vertical = div(index, @number_of_rows) * @square_size
        top_left = {horizontal, vertical}
        bottom_right = {horizontal + @square_size, vertical + @square_size}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    # Looks like a map but is the way to access the hex struct value
    %Identicon.Image{hex: hex}
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image),
    do: %Identicon.Image{image | color: {r, g, b}}

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    # fn() -> end is like a lambda function
    # the `rem()` is a helper method that will calculate a remainder (code % 2) in javascript
    odd_grid = Enum.filter(grid, fn {code, _index} -> rem(code, 2) == 0 end)

    %Identicon.Image{image | grid: odd_grid}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    blank_image = :egd.create(@grid_size, @grid_size)
    fill_color = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(blank_image, start, stop, fill_color)
    end)

    :egd.render(blank_image)
  end

  def mirror_row([first, second | _tail] = row), do: row ++ [second, first]

  def save_image(image, input), do: File.write("../#{input}.png", image)
end
