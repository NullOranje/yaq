defimpl Collectable, for: Yaq do
  @moduledoc false

  @impl true
  def into(original) do
    collector_fun = fn
      queue, {:cont, term} -> Yaq.enqueue(queue, term)
      queue, :done -> queue
      _queue, :halt -> :ok
    end

    {original, collector_fun}
  end
end
