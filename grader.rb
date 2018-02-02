require 'thor'
require 'pry'

class Grader < Thor
  REPO_PREFIX = "mpcs51030-2018-winter-assignment-".freeze

  desc "setup", "Make the directory and ask for usernames and repos"
  def setup
    num = assignment_number
    dir_name = "./hw-#{num}"

    Dir.mkdir(dir_name)

    ["rubric.txt", "usernames.txt"].each do |file|
      File.open("./#{dir_name}/#{file}", "w") {}
    end

    say "1. paste the rubric into hw-#{num}/rubric.txt, and usernames into usernames.txt", :green
    say "2. Next run `ruby grader.rb clone`\n", :green
  end

  desc "grade", "Start grading an assignment"
  def grade
    num = assignment_number
    say "Which person would you like to grade?", :green

    repos = all_repos(num) { |repo| repo } - [".", "..", ".DS_Store"]

    repos.each_with_index { |repo, ix| say "[#{ix}] - #{repo}" }
    input = STDIN.gets.chomp.to_i

    selected = repos[input]
    say "Grading #{selected}"

    path = "./hw-#{num}/repos/#{selected}/"
    system("open #{path} && vim #{path}rubric.txt")

  end

  desc "clone", "Download repos from Github"
  def clone
    num = assignment_number

    check_for_rubric num
    usernames = File.readlines("./hw-#{num}/usernames.txt").map(&:chomp)

    make_repos_dir num
    download_repos usernames, num

    copy_rubric_into_repos num
  end

  desc "push", "Push all repos to github"
  def push
    num = assignment_number

    all_repos(num) do |repo|
      command = "cd ./hw-#{num}/repos/#{repo}/; basename $PWD; tail -1 rubric.txt; echo '---';"
      command += "git aa; git  ci -m 'grade'; git push; cd - > /dev/null"
      system(command)
    end
  end

  desc "copy_rubric", "Copy rubric into everyone's directory"
  def copy_rubric
    num = assignment_number

    copy_rubric_into_repos num
  end

  desc "show_grades", "Print everyone's grades"
  def show_grades
    num = assignment_number

    all_repos(num) do |repo|
      command = "cd ./hw-#{num}/repos/#{repo}/; printf \"$(tail -1 rubric.txt) - $(basename $PWD)\n\";"
      command += "cd - > /dev/null"
      system(command)
    end
  end

  no_commands do
    def all_repos(num, &block)
      Dir.entries("./hw-#{num}/repos/").each do |repo|
        if ![".", "..", ".DS_Store" ].include? repo
          yield(repo)
        end
      end
    end

    def copy_rubric_into_repos num
      Dir.entries("./hw-#{num}/repos/").each do |f|
        next if f == "." or f == ".."
        command = `cp ./hw-#{num}/rubric.txt ./hw-#{num}/repos/#{f}/rubric.txt`

        system(command)
      end
    end

    def check_for_rubric(num)
      unless File.exist? "./hw-#{num}/rubric.txt"
        raise "Rubric file not found. Please add it into the hw-#{num} directory"
      end

      unless File.exist? "./hw-#{num}/usernames.txt"
        raise "Usernames file not found. Please add it into the hw-#{num} directory"
      end
    end

    def assignment_number
      ask("which assignment number are you grading?")
    end

    def make_repos_dir(num)
      Dir.mkdir("./hw-#{num}/repos")
    end

    def download_repos usernames, num
      usernames.each do |user|
        `git clone git@github.com:uchicago-mobi/#{REPO_PREFIX}#{num}-#{user}.git ./hw-#{num}/repos/#{user}`
      end
    end
  end
end

Grader.start(ARGV) if $PROGRAM_NAME == __FILE__
