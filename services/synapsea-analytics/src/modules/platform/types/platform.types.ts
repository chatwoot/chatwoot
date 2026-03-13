export type CanonicalEvent = {
  type: string;
  category: 'conversation' | 'message' | 'routing' | 'automation' | 'ai' | 'lead' | 'sla';
  producer: string;
  consumers: string[];
};

export type ServiceModule = {
  name: string;
  responsibility: string;
  endpoints: string[];
};

export type PlatformBlueprint = {
  architecture: 'event-driven-modular';
  layers: Array<{ name: string; description: string }>;
  services: ServiceModule[];
  realtime: {
    transport: 'websocket';
    channels: string[];
  };
};
