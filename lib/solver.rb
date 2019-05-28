# Solve a placement, to give a starting point for
# instructors to work from
# Currently implements the Hungarian Algorithm,
# see references at the bottom of this file

require 'matrix'

# For some reason Ruby matricies aren't mutable
# But apparently there's an easy way to make them so
# *sigh* sometimes I really do miss Python
class Matrix
  public :"[]=", :set_element, :set_component
end

# Safety checks for myself
class ProgrammingError < StandardError; end

# Raised when the solution does not converge
class SolutionError < StandardError; end

class Solver
  # For test introspection
  attr_reader :matrix, :students, :companies, :iterations

  # Constraints:
  #   Number of students must equal number of company slots
  #   initial_pairings must be empty
  #
  # Invariants:
  #   Students are rows and companies are columns
  #
  # Initialization and the initial reduction are both O(V^2).
  def initialize(classroom, initial_pairings=[])
    unless initial_pairings.empty?
      raise ArgumentError.new("Cannot yet handle initial pairings")
    end
    @rankings = classroom.rankings

    # Build row and column headers
    # (lists of students and company slots)
    @students = classroom.students
    @companies = []
    classroom.companies.each do |company|
      # If a company has multiple slots, add that many rows
      company.slots.times do
        @companies << company
      end
    end

    unless @students.length == @companies.length
      raise ArgumentError.new("Number of students (#{@students.length}) does not match number of company slots (#{@companies.length})")
    end

    @matrix = Matrix.build(@students.length, @companies.length) do |row, col|
      initial_cost(row, col)
    end

    # Convert all costs to positive values by adding 1+abs(lowest cost) to each
    offset =  @matrix.to_a.flatten.min.abs + 1
    @matrix = @matrix.map do |cost|
      cost + offset
    end

    initial_reduction
  end

  def solve
    # Iterate until we've found a complete assignment. Since we add at least one
    # zero to the reduced matrix every iteration, this is guaranteed to happen
    # in O(E) < O(V^2) iterations.
    # Finding the MM and MVC are both currently O(V^3), so our total runtime
    # is at most O(V^5). Pretty gross, and the internet claims we can get the
    # whole thing down to O(V^3), but since our V is at most 48 I don't think
    # it's an issue. Basically until someone complains about performance IDGAF
    @iterations = 0
    while (true)
      @iterations += 1

      # puts "Current matrix reduction:"
      # puts @matrix

      # First build a flow graph for the current reduced matrix
      flow_graph = build_flow_graph

      # puts "Built flow graph:"
      # puts flow_graph

      # Find the maximum matching, that is, a set of assignments
      # using the current reduced matrix. The slots in the array
      # represent companies (columns), and the values represent
      # students (rows). -1 means the company has no student assigned
      assignments = maximum_matching(flow_graph)

      # puts "Flow graph resulted in assignments:"
      # print assignments
      # puts

      # Safety: outside of -1, there should be no duplicate assignments
      real_assignments = assignments.select { |a| a >= 0 }
      if real_assignments.length != real_assignments.uniq.length
        raise ProgrammingError("maximum_matching returned a duplicate value in the assignment array: #{assignments}")
      end

      # If every company has a student assigned, we're done
      unless assignments.include?(-1)
        return build_pairings(assignments)
      end

      # If we've gotten here that means we're not done yet.
      # Need to reduce the matrix, then go again.
      # To reduce the matrix, we first convert our maximum matching
      # into a minimum vertex cover using Koning's graph theorem
      mvc_students, mvc_companies = minimum_vertex_cover(flow_graph, assignments)

      # puts "MVC (students, companies):"
      # print mvc_students
      # puts
      # print mvc_companies
      # puts

      reduce(mvc_students, mvc_companies)
    end
  end

private

  #
  # Initialization
  #

  # What is the initial cost for a student/company pair?
  # Requires @rankings, @students and @companies to have been initialized
  def initial_cost(row, col)
    # Retrieve the ranking for this student-company pair
    ranking = @rankings.find_by(student: @students[row], company: @companies[col])

    if ranking.nil?
      # Students who did not interview with a company are assigned a value of
      # Float::INFINITY, to represent the fact that they cannot intern there.
      # XXX: not sure how this affects performance
      return Float::INFINITY
    end

    # Currently, student preferences and interview results are 1 to 5,
    # with 1 the worst and 5 the best
    #
    # Our intuition about the problem is that there's a small difference
    # between an (incoming) 4 (inclined yes) and a 5 (strong yes),
    # but a large difference between a 2 (inclined no) and a 1 (strong no).
    #
    # To build the cost: subtract each number from 6 (so it's 5 to 1,
    # with 5 the worst and 1 the best) then multiply.
    # TODO DPR: might make sense to adopt this schema gloabally
    return -ranking.score
  end

  # Optimization: reduce the number of times the algorithm
  # iterates by seeding our matrix with some initial zeros
  # Runs in O(V^2)
  def initial_reduction
    # For each row, subtract the smallest cost from each element
    # Then repeat for columns

    # r and c are row and column indicies
    # row and column are actual vectors

    # puts "Pre-reduction"
    # puts @matrix

    # Reduce rows
    @matrix.row_count.times do |r|
      min = @matrix.row(r).min
      if min > 0
        @matrix.column_count.times do |c|
          @matrix[r,c] -= min
        end
      end
    end

    # Reduce columns
    @matrix.column_count.times do |c|
      min = @matrix.column(c).min
      if min > 0
        @matrix.row_count.times do |r|
          @matrix[r,c] -= min
        end
      end
    end
  end

  #
  # Maximum matching
  #

  # The binary flow graph is used to compute both the
  # maximum matching and the minimum vertex cover.
  def build_flow_graph
    return Matrix.build(@matrix.row_count) do |row, col|
      @matrix[row, col] == 0
    end
  end

  # Recursive subroutine based on DFS, that finds an assignment
  # for the student in row r if possible
  def find_match(flow_graph, r, seen, assignments)
    # try each company, one by one
    flow_graph.column_count.times do |c|
      # If this student-company pairing is a candidate, and
      # we haven't yet examined this company
      if flow_graph[r,c] and not seen[c]
        # Mark this company as seen
        seen[c] = true

        # If company c has no assigned student, or if
        # the currently assigned student can be switched
        # to a different company, we assign the student
        # to this company and call it good
        if assignments[c] < 0 or find_match(flow_graph, assignments[c], seen, assignments)
          assignments[c] = r
          return true
        end
      end
    end
    return false
  end

  # A matching is a set of edges (pairings) without any common
  # vertices (students or companies). A maximum matching is a
  # matching that contains the largest possible number of vertices.
  #
  # In this context, we're finding the maximum matching for our
  # matrix as it has been reduced so far, that is, including only
  # pairing where the current value is 0.
  #
  # To do so, we convert the matrix to a flow graph and use
  # a variant on the Ford-Fulkerson algorithm to find the
  # maximum matching.
  #
  # This method runs in O(V(V*E)) < O(V^3)
  # The internet claims it's possible to achieve O(V^2) by
  # using the matching from the previous step, but until
  # performance is an issue I'm not going to bother
  def maximum_matching(flow_graph)
    # Array to keep track of which student is assigned to which company
    # The value of assignments[c] is the student number s
    # assigned to company c, or -1 if no one is assigned
    assignments = [-1] * flow_graph.column_count

    flow_graph.row_count.times do |r|
      # Array to keep track of which companies
      # have been seen while attempting to place this student
      seen = [false] * flow_graph.column_count

      find_match(flow_graph, r, seen, assignments)
    end

    return assignments
  end

  #
  # Minimum vertex cover
  #

  # Implementation of the algorithm described by Konig's Theorem
  def minimum_vertex_cover(flow_graph, assignments)
    # Konig's theorm tells us that, given:
    #   a bipartate graph G, with vertices partitioned into students S and companies C,
    #     and edges E (all of which currently have cost 0, a.k.a. are marked true in the flow graph), and
    #   a maximum matching M (a subset of the edges in E),
    # a minim vertex cover K can be constructed via the following technique:
    #
    # Let S' be the (possible empty) set of students in S not connected by M
    # Define an alterating path as a path that alternates between
    #   edges in M and those not in M (doesn't matter which you start on)
    # Let S* be the set of students in S that are either in S', or can
    #   be reached by following an alternating path from S' (a superset of S')
    # Let C* be the set of companies in C that can be reached by such a path from S'
    # Then the MVC K can be defined as the union of students not in S* and companies in C*
    #
    # More formally:
    # S' = { s in S not connected by M }
    # S* = S' U { s in S reachable by an alternating path from S' }
    # C* = { c in C reachable by an alternating path from S' }
    # then
    # K = ( S - S* ) U C*
    #
    # How do we find vertices in S* and C*? BFS or DFS, of course!
    #
    # In the following code, S' will be called unmatched_students, and
    # S* and C* will be called reachable_[students|companies], respectively
    #
    # Note: the provided flow graph is not (quite) bipartate - it may contain
    # students or companies that are not connected to anything else. We'll have to
    # explicitly check for and filter these as we compute our MVC
    #
    # Since it's built around a DFS from each unmatched student,
    # I believe the runtime has an upper bound of O(V(V*E)) < O(V^3).
    # Because the visited list for the DFS is maintained between
    # students, it may just be O(V*E) < O(V^2), but I haven't
    # bothered to actually run the math yet

    # TODO DPR: how do results change if we swap S and C in the above?

    # First compute S', the set of students not assigned to a company by M,
    # but still with an edge in the flow graph
    unmatched_students = []
    flow_graph.row_count.times do |r|
      # If the student doesn't have an edge in the flow graph, or if
      # one of the edges for this student is in M, skip this student
      found_edge = false
      matched = false
      flow_graph.column_count.times do |c|
        if flow_graph[r, c]
          if assignments[c] == r
            matched = true
            break
          end
          found_edge = true
        end
      end

      unless matched or not found_edge
        unmatched_students << r
      end
    end

    # Safety: there should be no duplicates in unmatched_students
    if unmatched_students.uniq.length != unmatched_students.length
      raise ProgrammingError.new("in Konig, unmatched students contained a duplicate: #{unmatched_students}")
    end

    # Next, compute S* and C*, the sets of students and companies reachable
    # via an alternating path from S'. To do so, we use a DFS.
    visited_students = [false] * flow_graph.row_count
    visited_companies = [false] * flow_graph.column_count

    # Since DFS is (traditionally) recursive, we'll define a couple helper
    # methods: visit_company and visit_student
    # And yes, mutually recursive functions do work in Ruby
    # XXX DPR: there must be a better way to iterate across a range than
    #   flow_graph.row_count.times.[enumerable method]
    # Note that since each search starts at a student not connected by M,
    # odd legs in the path (student -> company) will always *not* be in M,
    # while even legs (company -> student) always *will* be in M.
    def visit_company(c, flow_graph, visited_companies, visited_students, assignments)
      # Check the visited list
      return if visited_companies[c]
      # Add to visited list
      visited_companies[c] = true

      # Iterate across rows
      flow_graph.row_count.times.select { |r|
        # Only investigate rows that are both in the graph and not yet visited,
        # and which *are* included in M for this column
        flow_graph[r, c] and not visited_students[r] and assignments[c] == r
      }.each do |r|
        visit_student(r, flow_graph, visited_companies, visited_students, assignments)
      end
    end

    # Has same form as visit_company, but with student and company swapped.
    # Refer to the above for comments. The only difference is in whether we're
    # looking for a vertex that is in M or not.
    def visit_student(r, flow_graph, visited_companies, visited_students, assignments)
      return if visited_students[r]
      visited_students[r] = true

      flow_graph.column_count.times.select { |c|
        # Only investigate columns that are both in the graph and not yet visited,
        # and which are *not* included in M for this row
        flow_graph[r, c] and not visited_companies[c] and assignments[c] != r
      }.each do |c|
        visit_company(c, flow_graph, visited_companies, visited_students, assignments)
      end
    end

    # Now that we've got our bipartate DFS methods set up, actually run the search!
    unmatched_students.each do |r|
      visit_student(r, flow_graph, visited_companies, visited_students, assignments)
    end

    # Now that we've got S* and C*, we can compute our MVC. Recall:
    # K = ( S - S* ) U C*
    # Note that a student is in S* if it was visited in the previous DFS, and
    # similarly for companies in C*
    # XXX DPR: each of these loops is n^2, we could probably do some
    # preproscessing for lists of matched students and companies to eliminate that
    mvc_students = flow_graph.row_count.times.map do |r|
      not visited_students[r] and flow_graph.row(r).include? true
    end

    mvc_companies = flow_graph.column_count.times.map do |c|
      visited_companies[c] and flow_graph.column(c).include? true
    end

    return mvc_students, mvc_companies
  end

  def reduce(mvc_students, mvc_companies)
    # We'll need the minimum non-zero value in the matrix
    min_value = @matrix.select { |v| v > 0 }.min

    # XXX DPR: Not sure if we'll always hit this
    # or if there's some thrashing behavior we might encounter
    if min_value == Float::INFINITY
      raise SolutionError.new("Cannot further reduce the placement matrix. Either there's a programming error or this classroom has no solution!")
    end

    # To reduce the matrix, we use the following method:
    # for each element (r,c) in the matrix:
    #   if r not in mvc_students and c not in mvc_companies (i.e. the cell in the matrix is not covered by any lines)
    #     subtract min_value from the element
    #   else if both r in mvc_students and c in mvc_companies (i.e. cell is covered by two lines)
    #     add min_value to the element
    # I haven't yet read or come up with a convincing explanation of why this works, but as
    # far as I can tell it's something to do with lowering our standards for
    # uncovered nodes while not letting covered nodes stagnate. Worth doing
    # some more serious thinking (especially if it ends up not working).
    @matrix.each_with_index do |value, r, c|
      if !mvc_students[r] and !mvc_companies[c]
        # Not covered -> lower our standards
        @matrix[r, c] = value - min_value

      elsif mvc_students[r] and mvc_companies[c]
        # Covered twice -> raise our stanards
        @matrix[r, c] = value + min_value

      end
    end
  end

  def build_pairings(assignments)
    # Note: none of these will be valid until attached to a placement
    pairings = []
    assignments.each_with_index do |r, c|
      pairings << Pairing.new(student: @students[r], company: @companies[c])
    end
    return pairings
  end
end


# Sources:
# Hungarian Algorithm:
#   http://www.math.harvard.edu/archive/20_spring_05/handouts/assignment_overheads.pdf
#   http://www.wikihow.com/Use-the-Hungarian-Algorithm
#   https://www.topcoder.com/community/data-science/data-science-tutorials/assignment-problem-and-hungarian-algorithm/
#   http://www.hungarianalgorithm.com/examplehungarianalgorithm.php
#
# Ruby matrix math:
#   http://rubylearning.com/blog/2013/04/04/ruby-matrix-the-forgotten-library/
#   https://ruby-doc.org/stdlib-2.3.0/libdoc/matrix/rdoc/Matrix.html
#
# Finding a maximum matching:
#   http://www.geeksforgeeks.org/maximum-bipartite-matching/
#
# Converting a maximum matching to a minimum vertex cover:
#   https://en.wikipedia.org/wiki/K%C5%91nig%27s_theorem_(graph_theory)#Proof
#   http://math.mit.edu/~goemans/18433S09/matching-notes.pdf
