defimpl Inspect, for: Yaq do
  @impl true
  def inspect(queue, _opts) do
    "#Yaq<length: #{queue.l_size + queue.r_size}>"
  end
end
