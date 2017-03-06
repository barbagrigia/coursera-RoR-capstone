class TagPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def destroy?
    admin?
  end

  def update?
    admin?
  end
end
