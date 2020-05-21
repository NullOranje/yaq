defmodule Yaq do
  @moduledoc """
  Yet Another Queue module for Elixir

  """

  @type value :: term()

  @opaque t :: %__MODULE__{
            l_data: list(),
            r_data: list(),
            l_size: non_neg_integer(),
            r_size: non_neg_integer()
          }

  @opaque t(value) :: %__MODULE__{
            l_data: list(value),
            r_data: list(value),
            l_size: non_neg_integer(),
            r_size: non_neg_integer()
          }

  defstruct l_data: [], r_data: [], l_size: 0, r_size: 0

  @doc """
  Concatenate an enumerable to the rear of the queue.

  ## Parameters

    - `q`: Current quque
    - `enum`: Items to add

  ## Examples

      iex> q = Yaq.new(1..10) |> Yaq.concat(11..20)
      #Yaq<length: 20>
      iex> Yaq.to_list(q)
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

  """
  @spec concat(t(), Enumerable.t()) :: t()
  def concat(%__MODULE__{} = q, enum),
    do: Enum.reduce(enum, q, fn x, acc -> Yaq.enqueue(acc, x) end)

  @doc """
  Concatenate an enumerable to the front of the queue.

  ## Parameters

    - `q`: Current quque
    - `enum`: Items to add

  ## Examples

      iex> q = Yaq.new(1..10) |> Yaq.concat_r(11..20)
      #Yaq<length: 20>
      iex> Yaq.to_list(q)
      [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  """
  @spec concat_r(t(), Enumerable.t()) :: t()
  def concat_r(%__MODULE__{} = q, enum),
    do: Enum.reverse(enum) |> Enum.reduce(q, fn x, acc -> Yaq.enqueue_r(acc, x) end)

  @doc """
  Push a new term onto the rear of the queue.

  ## Parameters

    - `q`: Current queue

    - `term`: Elixir term to enqueue

  ## Examples

      iex> q = Yaq.new()
      #Yaq<length: 0>
      iex> q = Yaq.enqueue(q, 1)
      #Yaq<length: 1>
      iex> q = Yaq.enqueue(q, 2)
      #Yaq<length: 2>
      iex> Yaq.to_list(q)
      [1, 2]

  """

  @spec enqueue(t(), term()) :: t()

  def enqueue(%__MODULE__{l_data: [], r_data: []}, term),
    do: %__MODULE__{l_data: [term], l_size: 1}

  def enqueue(%__MODULE__{} = q, term), do: %{q | r_data: [term | q.r_data], r_size: q.r_size + 1}

  @doc """
  Push a new term onto the front of the queue.

  ## Examples

      iex> q = Yaq.new()
      #Yaq<length: 0>
      iex> q = Yaq.enqueue_r(q, 1)
      #Yaq<length: 1>
      iex> q = Yaq.enqueue_r(q, 2)
      #Yaq<length: 2>
      iex> Yaq.to_list(q)
      [2, 1]

  """

  @spec enqueue_r(t(), term()) :: t()

  def enqueue_r(%__MODULE__{l_data: [], r_data: []}, term), do: enqueue(%__MODULE__{}, term)

  def enqueue_r(%__MODULE__{} = q, term),
    do: %{q | l_data: [term | q.l_data], l_size: q.l_size + 1}

  @doc """
  Create a new queue.

  ## Parameters

    * `enum` (optional): initial queue data

  ## Examples

      iex> Yaq.new()
      #Yaq<length: 0>
      
      iex> Yaq.new(1..10)
      #Yaq<length: 10>

  """

  @spec new() :: t()
  @spec new(Enumerable.t()) :: t()

  def new(enum \\ []) do
    data = Enum.to_list(enum)
    size = length(data)
    %__MODULE__{l_data: data, l_size: size}
  end

  @doc """
  Remove an item from the front of the queue.

  ## Parameters

    - `q`: The current queue
    - `default` (optional): Return value if the queue is empty. Defaults to `nil`

  ## Examples

      iex> {term, q} = Yaq.new(1..3) |> Yaq.dequeue()
      iex> term
      1
      iex> q
      #Yaq<length: 2>
      
      iex> {term, q} = Yaq.new() |> Yaq.dequeue()
      iex> term
      nil
      iex> q
      #Yaq<length: 0>
      
      iex> {term, q} = Yaq.new() |> Yaq.dequeue(:user_defined)
      iex> term
      :user_defined
      iex> q
      #Yaq<length: 0>

  """

  @spec dequeue(t()) :: {value(), t()}

  def dequeue(%__MODULE__{} = q, default \\ nil) do
    q = rebalance(q)

    case q.l_data do
      [] ->
        {default, q}

      [term] ->
        {term, %{q | l_data: [], l_size: 0}}

      [term | l_data] ->
        {term, %{q | l_data: l_data, l_size: q.l_size - 1}}
    end
  end

  @doc """
  Remove an item from the rear of the queue.

  ## Parameters

    - `q`: The current queue
    - `default` (optional): Return value if the queue is empty. Defaults to `nil`

   ## Examples

      iex> {term, q} = Yaq.new(1..3) |> Yaq.dequeue_r()
      iex> term
      3
      iex> q
      #Yaq<length: 2>

      iex> {term, q} = Yaq.new() |> Yaq.dequeue_r()
      iex> term
      nil
      iex> q
      #Yaq<length: 0>
      
      iex> {term, q} = Yaq.new() |> Yaq.dequeue_r(:user_defined)
      iex> term
      :user_defined
      iex> q
      #Yaq<length: 0>

  """

  @spec dequeue_r(t()) :: {value(), t()}

  def dequeue_r(%__MODULE__{} = q, default \\ nil) do
    q = rebalance(q)

    case q.r_data do
      [] ->
        dequeue(q, default)

      [term] ->
        {term, %{q | r_data: [], r_size: 0}}

      [term | r_data] ->
        {term, %{q | r_data: r_data, r_size: q.r_size - 1}}
    end
  end

  @doc """
  Return the front element of the queue.  Returns `nil` if empty

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new() |> Yaq.peek()
      nil

      iex> Yaq.new(1..3) |> Yaq.peek()
      1

  """

  @spec peek(t()) :: value()

  def peek(%__MODULE__{l_data: [], r_data: []}), do: nil

  def peek(%__MODULE__{} = q) do
    {value, _queue} = __MODULE__.dequeue(q)

    value
  end

  @doc """
  Returns the rear element of the queue.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new() |> Yaq.peek_r()
      nil

      iex> Yaq.new(1..3) |> Yaq.peek_r()
      3

  """

  @spec peek_r(t()) :: value()

  def peek_r(%__MODULE__{l_data: [], r_data: []}), do: nil

  def peek_r(q) do
    {value, _queue} = __MODULE__.dequeue_r(q)

    value
  end

  @doc """
  Fetches the front value from the queue.

  If the queue is empty, reutrns the tuple `{:error, new_queue}`.  Otherwise, returns the tuple `{{:ok, value}, q}`.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> = Yaq.new() |> Yaq.fetch()
      :error

      iex> {response, queue} = Yaq.new([1, 2, 3]) |> Yaq.fetch()
      iex> response
      {:ok, 1}
      iex> queue
      #Yaq<length: 2>

  """
  @spec fetch(t()) :: {value(), t()} | :error
  def fetch(%__MODULE__{l_size: 0, r_size: 0}), do: :error

  def fetch(%__MODULE__{} = q), do: dequeue(q)

  @doc """
  Fetches the front value from the queue.

  If the queue is empty, raises `Yaq.EmptyQueueError`.  Otherwise, returns the tuple `{value, q}`.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new() |> Yaq.fetch!()
      ** (Yaq.EmptyQueueError) empty queue

      iex> {response, queue} = Yaq.new([1, 2, 3]) |> Yaq.fetch!()
      iex> response
      1
      iex> queue
      #Yaq<length: 2>

  """
  @spec fetch!(t()) :: {value(), t()}
  def fetch!(%__MODULE__{l_size: 0, r_size: 0}), do: raise(Yaq.EmptyQueueError)
  def fetch!(%__MODULE__{} = q), do: dequeue(q)

  @doc """
  Fetches the rear value from the queue.

  If the queue is empty, reutrns the tuple `{:error, new_queue}`.  Otherwise, returns the tuple `{{:ok, value}, q}`.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> {response, queue} = Yaq.new() |> Yaq.fetch_r()
      iex> response
      :error
      iex> queue
      #Yaq<length: 0>

      iex> {response, queue} = Yaq.new([1, 2, 3]) |> Yaq.fetch_r()
      iex> response
      {:ok, 3}
      iex> queue
      #Yaq<length: 2>

  """
  @spec fetch_r(t()) :: {{:ok, value()}, t()} | {:error, t()}
  def fetch_r(%__MODULE__{l_size: 0, r_size: 0} = q), do: {:error, q}

  def fetch_r(%__MODULE__{} = q) do
    {value, q} = dequeue_r(q)

    {{:ok, value}, q}
  end

  @doc """
  Fetches the rear value from the queue.

  If the queue is empty, raises `Yaq.EmptyQueueError`.  Otherwise, returns the tuple `{value, q}`.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new() |> Yaq.fetch_r!()
      ** (Yaq.EmptyQueueError) empty queue

      iex> {response, queue} = Yaq.new([1, 2, 3]) |> Yaq.fetch_r!()
      iex> response
      1
      iex> queue
      #Yaq<length: 2>

  """
  @spec fetch_r!(t()) :: {value(), t()}
  def fetch_r!(%__MODULE__{l_size: 0, r_size: 0}), do: raise(Yaq.EmptyQueueError)
  def fetch_r!(%__MODULE__{} = q), do: dequeue(q)

  @doc """
  Reverse the queue.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new([1, 2, 3]) |> Yaq.reverse() |> Yaq.to_list()
      [3, 2, 1]

  """
  def reverse(%__MODULE__{} = q) do
    %{q | l_data: q.r_data, l_size: q.r_size, r_data: q.l_data, r_size: q.r_size}
  end

  @doc """
  Return the number of elements in the queue.

  ## Parameters
    
    - `q`: Current queue

  ## Examples

      iex> Yaq.new() |> Yaq.size()
      0

      iex> Yaq.new(1..3) |> Yaq.size()
      3

  """

  @spec size(t()) :: non_neg_integer()

  def size(%__MODULE__{} = q), do: q.l_size + q.r_size

  @doc """
  Return the elements of the queue as a list.

  ## Parameters

    - `q`: Current queue

  ## Examples

      iex> Yaq.new([1, 2, 3]) |> Yaq.to_list()
      [1, 2, 3]

  """

  @spec to_list(t()) :: list()

  def to_list(%__MODULE__{l_data: [], r_data: []}), do: []
  def to_list(%__MODULE__{} = q), do: q.l_data ++ Enum.reverse(q.r_data)

  # Rebalance the queue internal data if necessary
  @spec rebalance(t()) :: t()

  defp rebalance(%__MODULE__{l_data: [], r_data: []} = q), do: q

  defp rebalance(%__MODULE__{l_data: []} = q) do
    l_size = round(q.r_size / 2)
    r_size = q.r_size - l_size
    {r_data, l_data} = Enum.split(q.r_data, r_size)
    l_data = Enum.reverse(l_data)

    %__MODULE__{l_data: l_data, r_data: r_data, l_size: l_size, r_size: r_size}
  end

  defp rebalance(%__MODULE__{r_data: []} = q) do
    r_size = floor(q.l_size / 2)
    l_size = q.l_size - r_size
    {l_data, r_data} = Enum.split(q.l_data, l_size)
    r_data = Enum.reverse(r_data)

    %__MODULE__{l_data: l_data, r_data: r_data, l_size: l_size, r_size: r_size}
  end

  defp rebalance(q), do: q
end

defmodule Yaq.EmptyQueueError do
  defexception message: "empty queue"
end
