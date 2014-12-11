require 'rugged'

module Wave
  extend self

  REPO_PATH='/tmp/gitdo/'

  def gitdo(msg)
    case msg["cmd"]
    when "commit"
      reply = commit(msg, repo())
    when "read"
      reply = read(repo())
    end
  end

  def read(repo)
    #walker.sorting(Rugged::SORT_DATE)
    #walker.push(repo.head.target)
    #latest_commit = walker.find do |commit|
    #  commit.parents.size == 1 
    #end
    #sha = latest_commit.oid
  
    begin
      latest = repo.head.target
      oid = latest.tree.first[:oid]
      blob = repo.lookup(oid)
      ok({:doc => blob.content, :author => latest.author, :message => latest.message })
    rescue Exception => ex
      { :result => 1, :error => ex.message, :bt => ex.backtrace.join("\n") }
    end
  end

  def commit(msg, repo)
    oid = repo.write(msg["doc"]["text"], :blob)
    index = repo.index
    begin
      index.read_tree(repo.head.target.tree)
    rescue
    end
    index.add(:path => "document.md", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:committer] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:message] ||= "It's a commit!"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
    index.write()
    ok
  end

  def repo()
    begin
      Rugged::Repository.new(REPO_PATH)
    rescue
      Rugged::Repository.init_at(REPO_PATH)
    end
  end

  def ok(opts = {})
    { :result => 0}.merge(opts)
  end
end
