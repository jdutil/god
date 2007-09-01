require File.dirname(__FILE__) + '/helper'

module God
  class Process
    def fork
      raise "You forgot to stub fork"
    end
    
    def exec(*args)
      raise "You forgot to stub exec"
    end
  end
end

class TestProcessChild < Test::Unit::TestCase
  def setup
    @p = God::Process.new(:name => 'foo')
    @p.stubs(:test).returns true # so we don't try to mkdir_p
    Process.stubs(:detach) # because we stub fork
  end
  
  # valid?
  
  def test_valid_should_return_true_if_auto_daemonized_and_log
    @p.start = 'qux'
    @p.log = 'bar'
    
    assert @p.valid?
  end
  
  def test_valid_should_return_true_if_auto_daemonized_and_no_stop
    @p.start = 'qux'
    @p.log = 'bar'
    
    assert @p.valid?
  end
  
  def test_valid_should_return_true_if_uid_exists
    @p.start = 'qux'
    @p.log = 'bar'
    @p.uid = 'root'
    
    assert @p.valid?
  end
  
  def test_valid_should_return_true_if_uid_does_not_exists
    @p.start = 'qux'
    @p.log = 'bar'
    @p.uid = 'foobarbaz'
    
    no_stdout do
      assert !@p.valid?
    end
  end
  
  def test_valid_should_return_true_if_gid_exists
    @p.start = 'qux'
    @p.log = 'bar'
    @p.gid = 'wheel'
    
    assert @p.valid?
  end
  
  def test_valid_should_return_true_if_gid_does_not_exists
    @p.start = 'qux'
    @p.log = 'bar'
    @p.gid = 'foobarbaz'
    
    no_stdout do
      assert !@p.valid?
    end
  end
end

class TestProcessDaemon < Test::Unit::TestCase
  def setup
    @p = God::Process.new(:name => 'foo', :pid_file => 'blah.pid')
    @p.stubs(:test).returns true # so we don't try to mkdir_p
    Process.stubs(:detach) # because we stub fork
  end
  
  # valid?
  
  def test_valid_should_return_false_if_no_start
    no_stdout do
      assert !@p.valid?
    end
  end
  
  def test_valid_should_return_false_if_self_daemonized_and_no_stop
    @p.pid_file = 'foo'
    
    no_stdout do
      assert !@p.valid?
    end
  end
  
  def test_valid_should_return_false_if_self_daemonized_and_log
    @p.pid_file = 'foo'
    @p.log = 'bar'
    
    no_stdout do
      assert !@p.valid?
    end
  end
  
  # defaul_pid_file
  
  def test_default_pid_file
    assert_equal File.join(God.pid_file_directory, 'foo.pid'), @p.default_pid_file
  end
  
  # call_action
  # These actually excercise call_action in the back at this point - Kev
  
  def test_call_action_with_string_should_fork_exec 
    @p.start = "do something"
    IO.expects(:pipe).returns([StringIO.new('1234'), StringIO.new])
    @p.expects(:fork)
    Process.expects(:waitpid)
    @p.call_action(:start)
  end
  
  def test_call_action_with_lambda_should_call
    cmd = lambda { puts "Hi" }
    cmd.expects(:call)
    @p.start = cmd
    @p.call_action(:start)
  end
  
  def test_call_action_without_pid_should_write_pid
    # Only for start, restart
    [:start, :restart].each do |action|
      @p = God::Process.new(:name => 'foo')
      @p.stubs(:test).returns true
      IO.expects(:pipe).returns([StringIO.new('1234'), StringIO.new])
      @p.expects(:fork)
      Process.expects(:waitpid)
      File.expects(:open).with(@p.default_pid_file, 'w')
      @p.send("#{action}=", "run")
      @p.call_action(action)
    end
  end
  
  def test_call_action_should_not_write_pid_for_stop
    @p.pid_file = nil
    IO.expects(:pipe).returns([StringIO.new('1234'), StringIO.new])
    @p.expects(:fork)
    Process.expects(:waitpid)
    File.expects(:open).times(0)
    @p.stop = "stopping"
    @p.call_action(:stop)
  end
  
  def test_call_action_should_mkdir_p_if_pid_file_dir_existence_test_fails
    @p.pid_file = nil
    IO.expects(:pipe).returns([StringIO.new('1234'), StringIO.new])
    @p.expects(:fork)
    Process.expects(:waitpid)
    @p.expects(:test).returns(false, true)
    FileUtils.expects(:mkdir_p).with(God.pid_file_directory)
    File.expects(:open)
    @p.start = "starting"
    @p.call_action(:start)
  end
  
  # start!/stop!/restart!
  
  def test_start_stop_restart_bang
    [:start, :stop, :restart].each do |x|
      @p.expects(:call_action).with(x)
      @p.send("#{x}!")
    end
  end
end