# TODO
# Open button, showing a list of chains that can be opened

require 'yaml'

class Chain
  class << self
    attr_reader :last_date, :length, :chain
    
    def create(chain, file = 'chains.yaml')
      @chain = chain
      @data ||= {}
      @data.merge!( {chain => { :last_date => @last_date = 0, :length => @length = 0 }} )
      update_last_chain(chain)
      File.open( file, 'w' ) { |f| f.write @data.to_yaml }
    end
    
    def simple_date
      t = Time.now
      t.year * 1000 + t.yday
    end
    
    def update_last_chain(chain)
      @data[:last_chain] = @data[chain].merge({ :chain => chain })
    end
    
    def open( chain = :last_chain, file = 'chains.yaml' )
      @file = file
      if File.exists? file
        File.open( file, 'r' ) { |f| @data = YAML::load(f) }
        @last_date, @length  = @data[chain][:last_date], @data[chain][:length]
        @chain = (chain == :last_chain) ? @data[chain][:chain] : chain
        #if @data then @last_date, @length  = @data[:last_date], @data[:length]
        #else create(chain, file)
        #end
      else return false
      end
    end
    
    def list
      @data.keys - [:last_chain]
    end
    
    def add
      d = simple_date
      if d == @last_date then return false
      else
        @data[@chain] = { :length => @length += 1, :last_date => @last_date = d }
        update_last_chain(@chain)
        File.open( @file, 'w' ) { |f| f.write @data.to_yaml }
      end
    end
    
    def undo_add
      if @length == 0 then return false
      else
        @last_date % 1000 == 1 ? @last_date -= 435 : @last_date -= 1          # 435: @last_date = @last_date - 1000 + 365
        @data[@chain] = { :length => @length -= 1, :last_date => @last_date }
        update_last_chain(@chain)
        File.open( @file, 'w' ) { |f| f.write @data.to_yaml }
      end
    end
    
    def broken?
      t = Time.now
      t = t.year * 1000 + t.yday
      t > @last_date + 1
    end
  end
end

Shoes.app(:title => "Chainsaw", :width => 500) do 

  def checkmark
    image "sketchy checkmark.jpg", :width => 84, :height => 84
  end
  def xmark
    image "sketchy xmark.jpg", :width => 84, :height => 84
  end
  
  def create_chain
    Chain.create(chain) if chain = ask "What do you want to call your chain?"
  end
  
  def update_view
    @view.clear do
      if Chain.broken?
        para "Oh no! You broke the chain! It lasted for #{Chain.length} days..\n\n"
        Chain.length.times { xmark }
      else
        para "Your chain is #{Chain.length} days long! Woooot!!\n\n"
        Chain.length.times { checkmark }
      end
    end
  end
  
  background white
  
  button("New") do
    create_chain
    update_view
  end
  button("Open") do
    window(:width => 300, :height => 300) do
      Chain.list.each do |chain|
        button(chain) { Chain.open(chain); owner.update_view; close }
      end
    end
  end
  button("Chain") { update_view if Chain.add }
  button("Unchain") { update_view if Chain.undo_add }
  
  @view = flow(:width => 1.0, :top => 25, :left => 5)
  create_chain unless Chain.open
  update_view
  every(60) { update_view }
  
end
