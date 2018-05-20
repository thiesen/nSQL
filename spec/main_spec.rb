describe 'database' do
  def run_script(commands, persist: false)
    raw_output = nil

    IO.popen("./db test.db", 'r+') do |pipe|
      commands.each do |command|
        pipe.puts command
      end

      pipe.close_write

      raw_output = pipe.gets(nil)
    end

    File.delete('./test.db') unless persist

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
    ], persist: true)

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

  it 'prints constants' do
    script = [
      '.constants',
      '.exit',
    ]

    result = run_script(script)

    expect(result).to match_array([
      'nSQL> Constants:',
      "ROW_SIZE: 293",
      "COMMON_NODE_HEADER_SIZE: 6",
      "LEAF_NODE_HEADER_SIZE: 10",
      "LEAF_NODE_CELL_SIZE: 297",
      "LEAF_NODE_SPACE_FOR_CELLS: 4106",
      "LEAF_NODE_MAX_CELLS: 13",
      "nSQL> ",
    ])
  end

  it 'allows printing out the structure of a one-node btree' do
    script = [3, 1, 2].map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".btree"
    script << ".exit"

    result = run_script(script)

    expect(result).to match_array([
      "nSQL> Executed.",
      "nSQL> Executed.",
      "nSQL> Executed.",
      "nSQL> Tree:",
      "leaf (size 3)",
      "  - 0 : 3",
      "  - 1 : 1",
      "  - 2 : 2",
      "nSQL> "
    ])
  end
end
