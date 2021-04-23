defmodule KV.RegistryTest do
  use ExUnit.Case

  @moduletag :capture_log

  doctest Registry

  test "module exists" do
    assert is_list(KV.Registry.module_info())
  end

  # Ensure that the GenServer, `KV.Registry`, is started before tests.
  setup context do
    # `start_supervised!` is a function injected by `ExUnit.Case`. This function starts the server and links
    # the unit test process to that server. This linkage allows the unit test framework to stop and restart
    # the server between each and every test.
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    # Shopping **does not** exist when server started
    assert KV.Registry.lookup(registry, "shopping") == :error

    # Can find the created "shopping" bucket
    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Now that we have the "shopping" bucket, can I add an item
    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # Perform a bogus, synchronous request to ensure that the registry has processed the :DOWN message.
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes buckets on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with a non-normal reason
    Agent.stop(bucket, :shutdown)

    # Perform a bogus, synchronous request to ensure that the registry has processed the :DOWN message.
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "bucket can crash at any time", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Simulate a bucket crash by explicitly and synchronously shutting it down
    Agent.stop(bucket, :shutdown)

    # Now trying to call the dead process causes a :noproc exit
    catch_exit KV.Bucket.put(bucket, "milk", 3)
  end
end