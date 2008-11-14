class FuseEngine
end

class FuseDirectory < FuseEntry
end

class FuseFile < FuseEntry
end

class FuseEntry

## initialize ################################################################

  def initialize(directory, name)
    @directory = directory
    @name      = name
  end

## attributes ################################################################

  def directory
    @directory
  end

  def directory=(directory)
    move(directory)
  end

  def name
    @name
  end

  def name=(name)
    rename(name)
  end

## overloadables #############################################################

  def contents
    # overload
  end

  def contents=(contents)
    # overload
  end

  def move(directory)
    # overload
    @directory = directory
  end

  def rename(name)
    # overload
    @name = name
  end

private ######################################################################

  def fuse
    container.fuse
  end

end
