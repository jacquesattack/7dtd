#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'nokogiri'

f = File.open("recipes.xml")
@doc = Nokogiri::XML(f,&:noblanks)
f.close

@head = @doc.root

# update quantities received from recipes
@doc.xpath("//recipe").each {|n| n['count'] = 30}

## new recipes
def add_ingredients recipe,ingredients
  ingredients = [ingredients] if ingredients.instance_of? Hash
  ingredients.each {|ingredient|
    ing = Nokogiri::XML::Node.new "ingredient",@doc
    ingredient.each_pair {|k,v| ing[k] = v}
    recipe.add_child(ing.to_xml)
  }
end

def new_recipe name,count,ingredients
  recipe = Nokogiri::XML::Node.new "recipe",@doc
  recipe['name'],recipe['count'] = name,count
  add_ingredients(recipe,ingredients)
  @head.first_element_child.before(recipe)
end

## modify recipes
class ModifiedRecipe < Struct.new(:erase_all,:ingredients)
end

def change_recipe recipes_to_change
  @doc.xpath("//recipe").each {|n|
    if recipes_to_change.has_key?(n['name'])
      r = recipes_to_change[n['name']]

      if r.erase_all
        n.children.remove
      end
      
      r.ingredients.each {|ing|
        if !r.erase_all and n.children.any? {|c| c['name'] == ing['name']}
          already_modified = false
          n.children.each {|c|
            next if c['name'] != ing['name'] or already_modified
            ing.each_pair {|k,v|
              next if k == 'name' or already_modified
              c[k] = v
            }
            already_modified = true
          }
        else
          add_ingredients(n,ing)
        end
      } 
    end
  }
end


###########################################

############## new recipes
# auger recipe
new_recipe("auger",1,{'name' => 'scrapMetal', 'count' => 1, 'grid' => '0, 0'}) 
# for more ingredients, use an array like this:
#new_recipe("auger",1,[{'name' => 'scrapMetal', 'count' => 1, 'grid' => '0, 0'},{'name' => 'yuccaFiber', 'count' => 1, 'grid' => '1, 0'}]) 

# chainsaw recipe
new_recipe("chainsaw",1,{'name' => 'scrapMetal', 'count' => 1, 'grid' => '-1, 0'})

# gascan recipe
new_recipe("gasCan",1,{'name' => 'sand', 'count' => 1, 'grid' => '-1, 0'})

############## modded recipes
modded_recipe = {}
modded_recipe["crossbowBolt"] = ModifiedRecipe.new(true,[{'name' => 'scrapMetal', 'count' => 1, 'grid' => '1, -1'}]) # first argument is whether or not you want to blow away all the current ingredients
change_recipe(modded_recipe)

File.open("recipes-hacked.xml","w") {|f| @doc.write_xml_to f}
