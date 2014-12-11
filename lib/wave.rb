require 'gitlab_git'
require 'rugged'

module Wave
  extend self

  REPO_PATH='/tmp/example/example.git'
  BLOB_PATH="document.md"

  def gitdo(msg)
    case msg["cmd"]
    when "commit"
      reply = commit(msg, repo())
    when "read"
      reply = read(repo())
    end
  end

  def read(repo)
    begin
      commit = Gitlab::Git::Commit.last(repo)
      blob = Gitlab::Git::Blob.find(repo, commit.sha, BLOB_PATH)
      ok({:doc => blob.data, :author => commit.raw_commit.author, :message => commit.message })
    rescue Exception => ex
      { :result => 1, :error => ex.message, :bt => ex.backtrace.join("\n") }
    end
  end

  def commit(msg, repo)
    #GitLab::Git doesn't have support for commits so we use the raw rugged repo
    repo = repo.rugged
    oid = repo.write(msg["doc"]["text"], :blob)
    index = repo.index
    begin
      index.read_tree(repo.head.target.tree)
    rescue
    end
    index.add(:path => BLOB_PATH, :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:committer] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:message] ||= "It's a commit!"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
    #index.write()
    ok
  end

  def repo()
    begin
      Gitlab::Git::Repository.new(REPO_PATH)
    rescue
      Rugged::Repository.init_at(REPO_PATH, :bare)
      Gitlab::Git::Repository.new(REPO_PATH)      
    end
  end

  def ok(opts = {})
    { :result => 0}.merge(opts)
  end
end
