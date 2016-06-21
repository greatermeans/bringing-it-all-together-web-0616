require 'pry'

class Dog

  attr_accessor :name, :breed, :id

  def initialize(options)
  	@id = options[:id]
  	@breed = options[:breed]
  	@name = options[:name]
  end

  ATTRIBUTES = {
  	id: "INTEGER PRIMARY KEY AUTOINCREMENT",
  	name: "TEXT",
  	breed: "TEXT"
  }

  def self.public_attributes
  	ATTRIBUTES.keys.reject {|key| key == :id}
  end


  def self.create_table
  	drop_table
  	sql = <<-SQL 
  	CREATE TABLE dogs (
  	  id INTEGER PRIMARY KEY,
  	  name TEXT,
  	  breed TEXT)
  	SQL
  	DB[:conn].execute(sql)
  end

  def self.drop_table
  	sql = <<-SQL
  	DROP TABLE IF EXISTS dogs
  	SQL
  	DB[:conn].execute(sql)
  end

  def save
  	persisted? ? update : insert
  end

  def persisted?
  	!!self.id
  end

  def update
  	question_marks = (Dog.public_attributes.map {|key| "?"}).join(", ")
  	sql = <<-SQL
  	UPDATE dogs SET #{Dog.public_attributes.join(" = ?, ")} = ? WHERE id = #{self.id}
  	SQL

  	DB[:conn].execute(sql,*values)
  end

  def insert
  	question_marks = (Dog.public_attributes.map {|key| "?"}).join(", ")
  	sql = <<-SQL
  	INSERT INTO dogs (#{Dog.public_attributes.join(", ")}) VALUES (#{question_marks}) 
  	SQL
  	DB[:conn].execute(sql,*values)
  	@id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
  	self
  end

  def self.create(options)
  	new(options).save
  end

  def self.find_by_id(id)
  	sql = <<-SQL
  	  SELECT * FROM dogs WHERE dogs.id = ?
  	SQL
  	new_from_db(DB[:conn].execute(sql,id)[0])
  end

  def self.find_by_name(options)
  	if options.is_a?(String)
  	  sql = <<-SQL
  	  SELECT * FROM dogs WHERE name = ?
  	  SQL
  	  new_from_db(DB[:conn].execute(sql,options)[0])		
  	else
   	  sql = <<-SQL
  	  SELECT * FROM dogs WHERE name = ? AND breed = ?
  	  SQL
  	  new_from_db(DB[:conn].execute(sql,options[:name],options[:breed])[0])
  	end
  end

  def self.find_or_create_by(options)
  	find_by_name(options) != nil ? find_by_name(options) : create(options)
  end


  def values
  	self.class.public_attributes.map do |key|
  	  self.send(key)
  	end
  end

  def self.new_from_db(row)
  	if row != nil
  	  Dog.new(id: row[0],name: row[1],breed: row[2])
  	else
  		return nil
  	end
  end



end