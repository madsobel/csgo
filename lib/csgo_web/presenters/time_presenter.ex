defmodule Csgo.TimePresenter do
  def convert_time(total_seconds) when is_binary(total_seconds) do
    total_seconds
    |> String.to_float()
    |> convert_time()
  end

  def convert_time(total_seconds) when is_float(total_seconds) do
    total_seconds = round(total_seconds)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    format_time(minutes, seconds)
  end

  defp format_time(minutes, seconds) do
    String.pad_leading(Integer.to_string(minutes), 2, "0") <> ":" <>
    String.pad_leading(Integer.to_string(seconds), 2, "0")
  end
end
