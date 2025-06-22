{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    plugins = {
      glow = pkgs.fetchFromGitHub {
        owner = "Reledia";
        repo = "glow.yazi";
        rev = "2da96e3";
        hash = "sha256-4krck4U/KWmnl32HWRsblYW/biuqzDPysrEn76buRck=";
      };
    };

    settings = {
      plugin = {
        prepend_previewers = [
          {
            name = "*.md";
            run = "glow";
          }
        ];
      };
    };

    flavors = {
      flexoki-dark = pkgs.fetchFromGitHub {
        owner = "gosxrgxx";
        repo = "flexoki-dark.yazi";
        rev = "3e8cfba";
        hash = "sha256-W6Pzx48wr6PAiD7M+xn7n3jB4pOXXquqTaGY07VFPik=";
      };
    };

    theme = {
      flavor = {
        dark = "flexoki-dark";
      };
    };

    # theme = {
    #   # Manager section
    #   manager = {
    #     cwd = {
    #       fg = "#d0d0d0";
    #       bold = true;
    #     };
    #     hovered = {
    #       fg = "#c0c0c0";
    #       bg = "#303030";
    #     };
    #     preview_hovered = {
    #       underline = true;
    #     };
    #     find_keyword = {
    #       fg = "#c0c0c0";
    #       italic = true;
    #     };
    #     find_position = {
    #       fg = "#a0a0a0";
    #       bg = "reset";
    #       italic = true;
    #     };
    #     find_match = {
    #       fg = "#e0e0e0";
    #       bg = "#404040";
    #     };
    #     marker_copied = {
    #       fg = "#808080";
    #     };
    #     marker_cut = {
    #       fg = "#a0a0a0";
    #     };
    #     marker_marked = {
    #       fg = "#b0b0b0";
    #     };
    #     marker_selected = {
    #       fg = "#c0c0c0";
    #     };
    #     tab_active = {
    #       fg = "#d0d0d0";
    #       bg = "#303030";
    #       bold = true;
    #     };
    #     tab_inactive = {
    #       fg = "#707070";
    #     };
    #     tab_width = 1;
    #     border_symbol = "│";
    #     border_style = {
    #       fg = "#404040";
    #     };
    #     count_copied = {
    #       fg = "#b0b0b0";
    #     };
    #     count_cut = {
    #       fg = "#a0a0a0";
    #     };
    #     count_selected = {
    #       fg = "#c0c0c0";
    #     };
    #     # Custom syntax highlighting theme for code previews
    #     syntect_theme = builtins.toString (
    #       pkgs.writeTextFile {
    #         name = "zenwritten.tmTheme";
    #         text = ''
    #           <?xml version="1.0" encoding="UTF-8"?>
    #           <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    #           <plist version="1.0">
    #           <dict>
    #             <key>name</key>
    #             <string>Zenwritten</string>
    #             <key>settings</key>
    #             <array>
    #               <dict>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>background</key>
    #                   <string>#252525</string>
    #                   <key>caret</key>
    #                   <string>#d0d0d0</string>
    #                   <key>foreground</key>
    #                   <string>#d0d0d0</string>
    #                   <key>invisibles</key>
    #                   <string>#484848</string>
    #                   <key>lineHighlight</key>
    #                   <string>#303030</string>
    #                   <key>selection</key>
    #                   <string>#404040</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Comment</string>
    #                 <key>scope</key>
    #                 <string>comment</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#707070</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>String</string>
    #                 <key>scope</key>
    #                 <string>string</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#b0b0b0</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Number</string>
    #                 <key>scope</key>
    #                 <string>constant.numeric</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#a0a0a0</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Keyword</string>
    #                 <key>scope</key>
    #                 <string>keyword</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#c0c0c0</string>
    #                   <key>fontStyle</key>
    #                   <string>bold</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Function</string>
    #                 <key>scope</key>
    #                 <string>entity.name.function, meta.function-call, support.function</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#c8c8c8</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Variable</string>
    #                 <key>scope</key>
    #                 <string>variable</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#d0d0d0</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Class/Type</string>
    #                 <key>scope</key>
    #                 <string>entity.name.type, entity.name.class, entity.name.namespace, entity.name.scope-resolution</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#d8d8d8</string>
    #                 </dict>
    #               </dict>
    #               <dict>
    #                 <key>name</key>
    #                 <string>Storage type</string>
    #                 <key>scope</key>
    #                 <string>storage.type</string>
    #                 <key>settings</key>
    #                 <dict>
    #                   <key>foreground</key>
    #                   <string>#b8b8b8</string>
    #                   <key>fontStyle</key>
    #                   <string>italic</string>
    #                 </dict>
    #               </dict>
    #             </array>
    #             <key>uuid</key>
    #             <string>4A9891BD-F4BC-4083-A2F2-D1DBEEC3A044</string>
    #             <key>colorSpaceName</key>
    #             <string>sRGB</string>
    #             <key>semanticClass</key>
    #             <string>theme.dark.zenwritten</string>
    #           </dict>
    #           </plist>
    #         '';
    #       }
    #     );
    #   };
    #
    #   # Mode section
    #   mode = {
    #     normal_main = {
    #       fg = "#d0d0d0";
    #       bg = "#303030";
    #     };
    #     normal_alt = {
    #       fg = "#a0a0a0";
    #       bg = "#252525";
    #     };
    #     select_main = {
    #       fg = "#303030";
    #       bg = "#c0c0c0";
    #     };
    #     select_alt = {
    #       fg = "#404040";
    #       bg = "#a0a0a0";
    #     };
    #     unset_main = {
    #       fg = "#303030";
    #       bg = "#909090";
    #     };
    #     unset_alt = {
    #       fg = "#404040";
    #       bg = "#707070";
    #     };
    #   };
    #
    #   # Status section
    #   status = {
    #     separator_open = "";
    #     separator_close = "";
    #     separator_style = {
    #       fg = "#404040";
    #     };
    #     mode_normal = {
    #       fg = "#b0b0b0";
    #       bg = "#404040";
    #       bold = true;
    #     };
    #     mode_select = {
    #       fg = "#303030";
    #       bg = "#c0c0c0";
    #       bold = true;
    #     };
    #     mode_unset = {
    #       fg = "#303030";
    #       bg = "#a0a0a0";
    #       bold = true;
    #     };
    #     progress_label = {
    #       italic = true;
    #     };
    #     progress_normal = {
    #       fg = "#707070";
    #       bg = "#303030";
    #     };
    #     progress_error = {
    #       fg = "#b0b0b0";
    #       bg = "#303030";
    #     };
    #     permissions_t = {
    #       fg = "#b0b0b0";
    #     };
    #     permissions_r = {
    #       fg = "#a0a0a0";
    #     };
    #     permissions_w = {
    #       fg = "#c0c0c0";
    #     };
    #     permissions_x = {
    #       fg = "#d0d0d0";
    #     };
    #     permissions_s = {
    #       fg = "#707070";
    #     };
    #   };
    #
    #   # Which section
    #   which = {
    #     cols = 1;
    #     mask = {
    #       fg = "#808080";
    #       bg = "#252525";
    #     };
    #     cand = {
    #       fg = "#c0c0c0";
    #       bold = true;
    #     };
    #     rest = {
    #       fg = "#707070";
    #     };
    #     desc = {
    #       fg = "#909090";
    #     };
    #     separator = " → ";
    #     separator_style = {
    #       fg = "#404040";
    #     };
    #   };
    #
    #   # Input section
    #   input = {
    #     border = {
    #       fg = "#404040";
    #     };
    #     title = {
    #       fg = "#b0b0b0";
    #       bold = true;
    #     };
    #     value = {
    #       fg = "#d0d0d0";
    #     };
    #     selected = {
    #       fg = "#e0e0e0";
    #       bg = "#404040";
    #     };
    #   };
    #
    #   # Select section
    #   select = {
    #     border = {
    #       fg = "#404040";
    #     };
    #     active = {
    #       fg = "#d0d0d0";
    #       bg = "#303030";
    #     };
    #     inactive = {
    #       fg = "#707070";
    #     };
    #   };
    #
    #   # Tasks section
    #   tasks = {
    #     border = {
    #       fg = "#404040";
    #     };
    #     title = {
    #       fg = "#b0b0b0";
    #       bold = true;
    #     };
    #     hovered = {
    #       fg = "#d0d0d0";
    #       bg = "#303030";
    #     };
    #   };
    #
    #   # Help section
    #   help = {
    #     on = {
    #       fg = "#c0c0c0";
    #       bold = true;
    #     };
    #     run = {
    #       fg = "#a0a0a0";
    #       bold = true;
    #     };
    #     desc = {
    #       fg = "#707070";
    #     };
    #     hovered = {
    #       fg = "#d0d0d0";
    #       bg = "#303030";
    #     };
    #     footer = {
    #       fg = "#909090";
    #       italic = true;
    #     };
    #   };
    #
    #   # File type rules
    #   filetype = {
    #     rules = [
    #       # Archives
    #       {
    #         mime = "application/x-tar";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/x-compressed-tar";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/x-bzip-compressed-tar";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/x-xz-compressed-tar";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/zip";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/x-7z-compressed";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         mime = "application/x-rar";
    #         fg = "#c0c0c0";
    #       }
    #
    #       # Documents
    #       {
    #         mime = "text/plain";
    #         fg = "#d0d0d0";
    #       }
    #       {
    #         mime = "text/markdown";
    #         fg = "#c8c8c8";
    #       }
    #       {
    #         mime = "application/pdf";
    #         fg = "#b0b0b0";
    #       }
    #       {
    #         mime = "application/vnd.*";
    #         fg = "#c0c0c0";
    #       }
    #
    #       # Images
    #       {
    #         mime = "image/*";
    #         fg = "#a8a8a8";
    #       }
    #
    #       # Audio
    #       {
    #         mime = "audio/*";
    #         fg = "#a0a0a0";
    #       }
    #
    #       # Video
    #       {
    #         mime = "video/*";
    #         fg = "#909090";
    #       }
    #
    #       # Code
    #       {
    #         name = "*.rs";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.js";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.ts";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.py";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.sh";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.html";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.css";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.toml";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.yml";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.yaml";
    #         fg = "#d8d8d8";
    #       }
    #       {
    #         name = "*.json";
    #         fg = "#d8d8d8";
    #       }
    #
    #       # Executables
    #       {
    #         mime = "application/x-executable";
    #         fg = "#e0e0e0";
    #         bold = true;
    #       }
    #
    #       # Git
    #       {
    #         name = ".git";
    #         fg = "#707070";
    #       }
    #       {
    #         name = ".gitignore";
    #         fg = "#707070";
    #       }
    #       {
    #         name = ".gitmodules";
    #         fg = "#707070";
    #       }
    #
    #       # Config files
    #       {
    #         name = "*.conf";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         name = "*.ini";
    #         fg = "#c0c0c0";
    #       }
    #       {
    #         name = "*.cfg";
    #         fg = "#c0c0c0";
    #       }
    #
    #       # Hidden files
    #       {
    #         name = ".*";
    #         fg = "#707070";
    #       }
    #
    #       # Default directory
    #       {
    #         name = "*/";
    #         fg = "#c8c8c8";
    #       }
    #     ];
    #   };
    #
    #   # Icons section
    #   icon = {
    #     # Default icons for directories and files
    #     prepend_dirs = [
    #       {
    #         name = "*/";
    #         text = "";
    #         fg = "#c0c0c0";
    #       }
    #     ];
    #     prepend_files = [
    #       {
    #         name = "*";
    #         text = "";
    #         fg = "#a0a0a0";
    #       }
    #     ];
    #   };
    # };
  };
}
