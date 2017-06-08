defmodule ProgressBar do
  @total_bars 25

  def start_bar(total) do
    spawn(ProgressBar, :_progress_bar, [self(), 0, total])
  end

  def increment(progress_bar) do
    send progress_bar, :increment
  end

  def await() do
    receive do
      :finished -> :ok
    end
  end

  def _progress_bar(parent, count, total) do
    bars_count = round(count / total * @total_bars)
    IO.write("\r["
      <> String.duplicate("=", bars_count)
      <> String.duplicate(" ", @total_bars - bars_count)
      <> "] #{count} / #{total}")

    receive do
      :increment ->
        next = count + 1
        if next == total do
          send parent, :finished
          IO.write("\r")
        else
          _progress_bar(parent, next, total)
        end
    end
  end
end
