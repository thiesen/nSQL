describe 'database' do
  def run_script(commands)
    raw_output = nil

    IO.popen('./db', 'r+') do |pipe|
      commands.each do |command|
        pipe.puts command
      end

      pipe.close_write

      raw_output = pipe.gets(nil)
    end
    raw_output.split("\n")
  end

  it 'inserts and retrieves a row' do
    result = run_script([
      'insert 1 xunda xunda@example.com',
      'select',
      '.exit',
    ])

    expect(result).to match_array([
      'nSQL> Executed.',
      'nSQL> (1, xunda, xunda@example.com)',
      'Executed.',
      'nSQL> ',
    ])
  end

  it 'prints error message when table is full' do
    script = (1..1401).map do |i|
      "insert #{i} user#{i} email#{i}@example.com"
    end

    script << '.exit'

    result = run_script(script)

    expect(result[-2]).to eq ('nSQL> Error: Table full.')
  end

  it 'allows inserting strings that are the maximum length' do
    long_username = 'a' * 32
    long_email = 'a' * 255
    script = [
      "insert 1 #{long_username} #{long_email}",
      'select',
      '.exit',
    ]

    result = run_script(script)

    expect(result).to match_array([
      'nSQL> Executed.',
      "nSQL> (1, #{long_username}, #{long_email})",
      'Executed.',
      'nSQL> ',
    ])
  end

  it 'prints error message if strings are too long' do
    long_username = 'a' * 33
    long_email = 'a' * 257

    script = [
      "insert 1 #{long_username} #{long_email}",
      'select',
      '.exit',
    ]

    result = run_script(script)

    expect(result).to match_array([
      'nSQL> String is too long.',
      'nSQL> Executed.',
      'nSQL> ',
    ])
  end

  it 'prints an error message if id is negative' do
    script = [
      'insert -1 xunda dunha@example.org',
      'select',
      '.exit',
    ]

    result = run_script(script)

    expect(result).to match_array([
      'nSQL> ID must be positive.',
      'nSQL> Executed.',
      'nSQL> ',
    ])
  end

  it 'keeps data after closing connection' do
    result1 = run_script([
      'insert 1 xunda xunda@dunha.com',
      'select',
      '.exit',
    ])

    expect(result1).to match_array([
      'nSQL> Executed.',
      'nSQL> ',
    ])

    result2 = run_script([
      'select',
      '.exit',
    ])

    expect(result2).to match_array([
      'nSQL> (1, xunda, xunda@dunha.com)',
      'Executed.',
      'nSQL> ',
    ])
  end
end
