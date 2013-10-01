require 'spec_helper'

describe 'region routing' do
  describe 'paths that should work' do

    it 'routes to #create' do
      expect(:post => '/regions').to route_to('regions#create')
    end

    it 'routes to #new' do
      expect(:get => '/regions/new').to route_to('regions#new')
    end

    it 'routes to #update' do
      expect(:put => '/regions/1').to route_to('regions#update', :id => '1')
    end

    it 'routes to #destroy' do
      expect(:delete => '/regions/1').to route_to('regions#destroy', :id => '1')
    end

  end

  describe 'paths that should not work' do

    it 'should not route to #index' do
      expect(:get => '/regions').not_to be_routable
    end

    it 'should not route to #show' do
      expect(:get => '/regions/1').not_to be_routable
    end

    it 'should not route to #edit' do
      expect(:get => '/regions/1/edit').not_to be_routable
    end
  end
end