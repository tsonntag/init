dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

module Init
  autoload :AbstractItem,    'init/abstract_item'
  autoload :AbstractServer,  'init/abstract_server'
  autoload :Application,     'init/application'
  autoload :Client,          'init/client'
  autoload :Init,            'init/init'
  autoload :Periodic,        'init/periodic'
  autoload :ProcessItem,     'init/process_item'
  autoload :ProcessServer,   'init/process_server'
  autoload :ThreadItem,      'init/thread_item'
  autoload :ThreadServer,    'init/thread_server'
end
