defimpl Enumerable, for: Yaq do
  @moduledoc false

  @impl true
  def count(%Yaq{} = q), do: {:ok, Yaq.size(q)}

  @impl true
  def member?(_enum, _term), do: {:error, __MODULE__}

  @impl true
  def reduce(%Yaq{}, {:halt, acc}, _fun), do: {:halted, acc}

  def reduce(%Yaq{} = enum, {:cont, acc}, fun) do
    case Yaq.size(enum) do
      0 ->
        {:done, acc}

      _ ->
        {term, q} = Yaq.dequeue(enum)
        reduce(q, fun.(term, acc), fun)
    end
  end

  @impl true
  def slice(_enum), do: {:error, __MODULE__}
end
