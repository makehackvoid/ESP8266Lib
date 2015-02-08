-- Copyright 2015 MHV / David Lyon All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, are
-- permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice, this list of
--       conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright notice, this list
--       of conditions and the following disclaimer in the documentation and/or other materials
--       provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY MHV ''AS IS'' AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
-- FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BART VAN STRIEN OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of MHV.
--
-- The above license is known as the Simplified BSD license.

config = {}

local config_name = 'settings.ini'

function load_config()
   file.open(config_name)
   local l = file.readline()
   while l ~= nil do
      local k,v
      if l ~= nil then 
          local epos = string.find(l,'=')
          if epos ~= nil then
               k = string.sub(l,0,epos-1)
               v = string.sub(l,epos+1)
               config[k] = v
               end
          end
      l = file.readline()
      end
   end
