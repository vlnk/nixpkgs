{ config, lib, pkgs, ... }:

with lib;

let

  cfgC = config.services.synergy.client;
  cfgS = config.services.synergy.server;

in

{
  ###### interface

  options = {

    services.synergy = {

      # !!! All these option descriptions needs to be cleaned up.

      client = {
        enable = mkEnableOption "the Synergy client (receive keyboard and mouse events from a Synergy server)";

        screenName = mkOption {
          default = "";
          type = types.str;
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            ourselves to the server.
          '';
        };
        serverAddress = mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The server address is of the form: [hostname][:port].  The
            hostname must be the address or hostname of the server.  The
            port overrides the default port, 24800.
          '';
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = lib.mdDoc "Whether the Synergy client should be started automatically.";
        };
      };

      server = {
        enable = mkEnableOption "the Synergy server (send keyboard and mouse events)";

        configFile = mkOption {
          type = types.path;
          default = "/etc/synergy-server.conf";
          description = lib.mdDoc "The Synergy server configuration file.";
        };
        screenName = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            this screen in the configuration.
          '';
        };
        address = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc "Address on which to listen for clients.";
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = lib.mdDoc "Whether the Synergy server should be started automatically.";
        };
        tls = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc ''
              Whether TLS encryption should be used.

              Using this requires a TLS certificate that can be
              generated by starting the Synergy GUI once and entering
              a valid product key.
            '';
          };

          cert = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "~/.synergy/SSL/Synergy.pem";
            description = lib.mdDoc "The TLS certificate to use for encryption.";
          };
        };
      };
    };

  };


  ###### implementation

  config = mkMerge [
    (mkIf cfgC.enable {
      systemd.user.services.synergy-client = {
        after = [ "network.target" "graphical-session.target" ];
        description = "Synergy client";
        wantedBy = optional cfgC.autoStart "graphical-session.target";
        path = [ pkgs.synergy ];
        serviceConfig.ExecStart = ''${pkgs.synergy}/bin/synergyc -f ${optionalString (cfgC.screenName != "") "-n ${cfgC.screenName}"} ${cfgC.serverAddress}'';
        serviceConfig.Restart = "on-failure";
      };
    })
    (mkIf cfgS.enable {
      systemd.user.services.synergy-server = {
        after = [ "network.target" "graphical-session.target" ];
        description = "Synergy server";
        wantedBy = optional cfgS.autoStart "graphical-session.target";
        path = [ pkgs.synergy ];
        serviceConfig.ExecStart = ''${pkgs.synergy}/bin/synergys -c ${cfgS.configFile} -f${optionalString (cfgS.address != "") " -a ${cfgS.address}"}${optionalString (cfgS.screenName != "") " -n ${cfgS.screenName}"}${optionalString cfgS.tls.enable " --enable-crypto"}${optionalString (cfgS.tls.cert != null) (" --tls-cert=${cfgS.tls.cert}")}'';
        serviceConfig.Restart = "on-failure";
      };
    })
  ];

}

/* SYNERGY SERVER example configuration file
section: screens
  laptop:
  dm:
  win:
end
section: aliases
    laptop:
      192.168.5.5
    dm:
      192.168.5.78
    win:
      192.168.5.54
end
section: links
   laptop:
       left = dm
   dm:
       right = laptop
       left = win
  win:
      right = dm
end
*/
