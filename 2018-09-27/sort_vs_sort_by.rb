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
# Prerequisite in order to understand benchmarks below is understanding how
# #sort_by works.
#
# General steps are:
#  1. execute block for each element in a collection
#  2. create a temporary array; use block return values as keys of a new array
#
#     [
#       [:key_1,:element_1], --> 1st tuple
#       [:key_2,:element_2], --> 2nd tuple
#       .
#       .
#       [:key_n,:element_n], --> nth tuple
#     ]
#  3. sort tuples using their keys
#  4. extract elements from the sorted array
#  5. put extracted elements in a resulting array
#

#
# *---------------------*
# | TIP - method naming |
# *---------------------*
#
# #sort_by uses "_by" suffix in the name in order to indicate that a return
# value from the block will be used to sort original elements of the collection.
#
# Think about it! :)
#

#
# *-----------*
# | block API |
# *-----------*
#
# #sort takes two arguments in the block, while #sort_by takes one. This
# denotes different usage.
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
# #sort is faster because performing #<=> on integers is a cheap operation,
# whereas #sort_by has to create a temporary array with keys identical to
# their values first and then sort it out.
#
# In this case, creating #sort_by temporary array is more expensive then
# executing #sort blocks.
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
# #sort_by is faster because block execution is cheap and sorting a temporary
# array is straightforward. Meanwhile, #sort has to instantiate two File objects,
# call #mtime on each, perform comparison using spaceship operator and
# do it N - 1 times (where N is the number of collection elements).
#
# In this case, creating #sort_by temporary array and sorting its elements is
# cheaper then executing #sort blocks.
#

#
# *-------------------*
# | When to use which |
# *-------------------*
#
# USE SORT when you have to compare two objects and perform simple computation.
# Such as comparing via **spaceship operator**.
#
# USE SORT_BY when computation is expensive, or would be if #sort was used.
#
