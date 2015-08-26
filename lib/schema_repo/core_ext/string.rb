class String
  def constantize
    SchemaRepo::StringUtils.constantize self
  end

  def demodulize
    SchemaRepo::StringUtils.demodulize self
  end

  def underscore
    SchemaRepo::StringUtils.underscore self
  end
end
