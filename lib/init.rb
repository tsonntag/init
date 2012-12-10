dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

module Init
  autoload :AbstractItem,    'init/abstract_item'
  autoload :ThreadItem,      'init/thread_item'
  autoload :ProcessItem,     'init/process_item'
  autoload :Client,          'init/client'
  autoload :AbstractServer,  'init/abstract_server'
  autoload :ProcessServer,   'init/process_server'
  autoload :ThreadServer,    'init/thread_server'
  autoload :Periodic,        'init/periodic'
  autoload :Application,     'init/application'
end
