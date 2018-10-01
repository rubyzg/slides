require "benchmark"

######################################
#                                    #
#   Enumerable - #sort & #sort_by    #
#                                    #
#  Performance and usage comparison  #
#                                    #
######################################

#
# *---------------------*
# | How #sort_by works? |
# *---------------------*
#
# Prerequisite in order to understand the following benchmarks is understanding
# how #sort_by works.
#
# It creates a temporary, intermediate array, with a following structure...
#   [
#     [:key_1,:element_1],
#     [:key_2,:element_2],
#     .
#     .
#     [:key_n,:element_n],
#   ]
# then it uses generated keys of that array to sort elements from the original
# collection.
#

#
# *---------------------*
# | TIP - method naming |
# *---------------------*
#
# #sort_by uses "_by" suffix in the name in order to indicate to you that
# a return value from the block will be used to sort original elements
# of the collection.
#
# Think about it! :)
#

#
# *-----------*
# | block API |
# *-----------*
#
# #sort takes two arguments in the block, while #sort_by takes one.
# This denotes fundamentally different usage between the two.
#

#
# *----------------*
# | 1. Simple sort |
# *----------------*
#
# Sorting integers from one, to one million.
#

Benchmark.bm(10) do |run|
  unordered_numbers = (1..1_000_000).to_a.shuffle

  run.report("Sort")    { unordered_numbers.sort }
  run.report("Sory by") { unordered_numbers.sort_by { |e| e } }
end

#
# Result - #sort is faster
# ------------------------
#
#                  user     system      total        real
# Sort         0.210000   0.010000   0.220000 (  0.221937)
# Sory by      1.150000   0.010000   1.160000 (  1.260971)
#
# Interpretation
# --------------
#
# #sort is faster because performing #<=> on integers is a cheap operation, whereas
# #sort_by has to create a temporary array with keys identical to their values
# first and then sort out that temporary array.
#
# In this case, creating #sort_bys' temporary array is more expensive then
# executing #sorts' blocks.
#

#
# *-----------------*
# | 2. Complex sort |
# *-----------------*
#
# Sorting ten thousand files by their modification time.
#

Benchmark.bm(10) do |run|
  test_files = Dir["./test_files/*"]

  run.report("Sort") do
    test_files.sort { |f1, f2| File.new(f1).mtime <=> File.new(f2).mtime }
  end

  run.report("Sort by") do
    test_files.sort_by { |f| File.new(f).mtime }
  end
end

#
# Result - #sort_by is faster
# ---------------------------
#
#                  user     system      total        real
# Sort         1.960000   3.810000   5.770000 (  6.117591)
# Sort by      0.120000   0.170000   0.290000 (  0.302010)
#
# Interpretation
# --------------
#
# #sort_by is faster because executing block execution is cheap and sorting out
# a temporary array is straightforward. Meanwhile, #sort has to create two File
# objects, call #mtime on each, perform comparison using spaceship operator and
# it has to do it N - 1 times, where N is the number of collection elements.
#
# In this case, creating #sort_bys' temporary array and sorting its elements is
# cheaper then executing #sorts' blocks.
#

#
# *-------------------*
# | When to use which |
# *-------------------*
#
# USE SORT when you have to compare two objects and perform simple computation.
# Such as doing comparison via **spaceship operator**.
#
# USE SORT_BY when computation you have to perform is expensive, or would be
# more expensive if #sort was used.
#
