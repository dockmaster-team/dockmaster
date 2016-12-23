require 'fileutils'

RSpec.describe Dockmaster::DocParser do
  default_store = Dockmaster::Store.new(nil, :none, '')

  context 'with blank input' do
    it 'returns the default empty Store' do
      store = Dockmaster::DocParser.parse_string('', default_store)

      expect(store).to eq(default_store)
    end
  end

  context 'with one module' do
    it 'returns a Store with one module' do
      source_str = <<-END
module TestModule
end
      END

      store = Dockmaster::Store.new(nil, :none, '')
      store = Dockmaster::DocParser.parse_string(source_str, store)

      expect(store.children).not_to be_empty

      mod_store = store.children[0]

      expect(mod_store.type).to eq(:module)
      expect(mod_store.name).to eq(:TestModule)
    end
  end

  context 'with one module with documentation' do
    it 'returns a Store with one module with formatted documentation' do
      source_str = <<-END
# Documentation
#
# @return test
module TestModule
end
      END

      store = Dockmaster::Store.new(nil, :none, '')
      store = Dockmaster::DocParser.parse_string(source_str, store)

      store.parse_see_links
      store.parse_docs

      expect(store.children).not_to be_empty

      mod_store = store.children[0]

      expect(mod_store.type).to eq(:module)
      expect(mod_store.name).to eq(:TestModule)
      expect(mod_store.docs.description).to eq('Documentation')
      expect(mod_store.docs[:return]).to eq('test')
    end
  end

  context 'with a file containing one module' do
    it 'returns a Store with one module' do
      store = Dockmaster::Store.new(nil, :none, '')
      store = Dockmaster::DocParser.parse_file(File.join(Dir.pwd, 'spec/files/testfile_doc_parser.rb'), store)

      store.parse_see_links
      store.parse_docs

      expect(store.children).not_to be_empty

      mod_store = store.children[0]

      expect(mod_store.type).to eq(:module)
      expect(mod_store.name).to eq(:TestModule)
      expect(mod_store.docs.description).to eq('Documentation')
      expect(mod_store.docs[:author]).to eq('test')
    end
  end

  describe '.begin' do
    it 'finds all source files and parses them into a Store with correct documentation' do
      Dir.chdir('spec/files/parser_test') do
        store = Dockmaster::DocParser.begin

        expect(store.children.length).to eq(1)
        mod = store.children[0]
        expect(mod.rb_string).to eq('TestFiles')
        expect(mod.children.length).to eq(2)
        class1 = mod.children[0]
        class2 = mod.children[1]

        expect(class1.rb_string).to eq('TestFiles::TestFile1')
        expect(class1.docs.description).to eq('Test documentation for TestFile1')
        expect(class1.field_data).to have_key(:TEST1)
        expect(class1.field_data[:TEST1].docs.description).to eq('A field (1)')
        expect(class1.method_data).to have_key(:test_method_1)
        expect(class1.method_data[:test_method_1].docs.description).to eq('A method (1)')
        expect(class1.method_data[:test_method_1].docs[:params]).to eq('test' => 'desc(1)')
        expect(class1.method_data[:test_method_1].docs[:return]).to eq('test(1)')

        expect(class2.rb_string).to eq('TestFiles::TestFile2')
        expect(class2.docs.description).to eq('Test documentation for TestFile2')
        expect(class2.field_data).to have_key(:TEST2)
        expect(class2.field_data[:TEST2].docs.description).to eq('A field (2)')
        expect(class2.method_data).to have_key(:test_method_2)
        expect(class2.method_data[:test_method_2].docs.description).to eq('A method (2)')
        expect(class2.method_data[:test_method_2].docs[:params]).to eq('test' => 'desc(2)')
        expect(class2.method_data[:test_method_2].docs[:return]).to eq('test(2)')
      end
    end
  end
end
