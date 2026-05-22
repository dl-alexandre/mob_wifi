ExUnit.configure(exclude: [:hardware])
Application.ensure_all_started(:telemetry)
ExUnit.start()
