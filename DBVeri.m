classdef DBVeri < handle
% FLAGS
% -1
% 0
% 1 - updating
% 2 - locked
% 3 - archvie
properties
    tableName
    aliasName
    primaryKey
    aliasKeys
    bAlias
end
properties(Access=?Veri)
    mms
    V
end
methods(Static)
    function obj=read(connectFname,schemaFname,tableName)
        [cfg]=Cfg.read(cfgFname);
        [schema]=Cfg.read(schemaFname);
        mms=MMS('schema_fname',schemaFname,'connect_fname',cfgFname);
        obj=DBVeri(mms);
    end
end
methods
    function obj=DBVeri(mms,tableName)
        obj.mms=mss;
        obj.tableName=table;
        obj.mss.connect();
        obj.getPrimaryKey();
        obj.getAliasKey();
        obj.getPrimaryTable();
    end
    function obj=getPrimaryKey()
        % XXX
        % PRIMARY
    end
    function obj=getUnique()
        % XXX
    end
    function obj=getAliasKey()
        obj.aliasName=[obj.tableName '_alias'];
        if isfield(obj.mss.Schemas,{obj.aliasName})
            obj.aliasKeys=obj.Schemas{obj.aliasName}.keys;
            obj.bAlias=true;
        end
    end
    function out=getLastHostname()
        % XXX
    end
    function out=getHostnames()
        % XXX
    end
    function out=getUpdatedHostnames()
        % XXX
    end
%%% GET ALL
    function lsAll(obj)
        out=obj.mss.select(obj.PrimaryKey);
    end
%%% INDIVIDUAL
%% GET
    function out=getEntry(obj,name)
        out=obj.get(name);
    end
    function out=getLock(obj,name)
        out=obj.get(name,'lock');
    end
    function out=getLastEdit(obj,name)
        out=obj.get(name,'lastEdit');
    end
    function out=getCompleted(obj,name)
        out=obj.get(name,'completed');
    end
    function out=getTotal(obj,name)
        out=obj.get(name,'total');
    end
    function out=getCompletion(obj,name)
        obj.get(name,'completed','total');
        % XXX
    end
    function out=getCompletionTime(obj,name, alias,varargin)
        out=obj.get(name,'completion');
    end
    function out=getCreationTime(obj,name, alias,varargin)
        out=obj.get(name,'creation');
    end
    function out=getRunTime(obj,name, alias,varargin)
        out=obj.get(name,'runtime');
    end
    function out=getAlias(obj,name)
        out=obj.get_alias(name);
    end
    function out=renameAlias(obj,name,alias,newalias);
        obj.rename_alias(name,alias,newalias);
    end
%% UPDATE
    function out=udpateProgress(obj,name, addRunTime, progress, completion)
        completion=parse_completion(completion);
        rt=obj.getRunTime()+obj.parse_time(addRuntime);

        out=obj.set(obj.primaryKey,name, ...
                             'runtime',rt, ...
                             'progress',pr, ...
                             'completion',completion ...
                            );
    end
    function obj=rename(obj,name,newname)
        obj.set(name,obj.PrimaryKey,newname);
        if obj.bAliases
            obj.rename_alias_names(name,newName);
        end
    end
    function obj=renameFlds(obj,name, varargin)
        obj.set(obj.primaryKey,name,varargin{:});
    end
    function obj=delete(obj,name)
        obj.rm(name);
    end
    function obj=addAlias(obj,name,alias,varargin)
        obj.add_alias(name,alias,varargin{:});
    end
    function obj=rmAlias(obj,alias,varargin)
        obj.rm_alias(name,alias,varargin{:});
    end
%% FLAGS

    function obj=flagUpdating(obj,name)
        obj.flag(name,'updating');
    end
    function obj=flagLock()
        obj.flag(name,'lock');
    end
    function obj=flagArchive()
        obj.flag(name,'archive');
    end
    function obj=unflagUpdating(obj,name)
        obj.unflag(name,'updating');
    end
    function obj=unFlagLock()
        obj.unflag(name,'lock');
    end
    function obj=unFlagArchive()
        obj.unflag(name,'archive');
    end
end
methods(Access=private)
    function name=parse_name(obj,name)
        % XXX check if alias
    end
    function completion=parse_completion(obj,completion)
        if isempty(completion) || ~obj.completion
            completion='NULL';
        elseif isequal(obj.completion,true)
            completion='NOW()';
        else
            completion=parse_timestamp(completion);
        end
    end
    function obj=parse_alias_entry(obj,alias,vargs)
        % XXX
    end
    function obj=check_lock(obj,name)
        out=obj.Entry.select(obj.primaryKey,name,'flag');
        % XXX
    end
%% MOVE XXX
    function timestamp=parse_timestamp(obj,timestamp)
        % XXX
    end
    function time=parse_time(obj,time)
        % XXX
    end
    function out=get(obj,name,varargin)
        name=obj.parse_name(name);
        obj.useTable(obj.tableName);
        if nargin < 3
            out=obj.mms.Entry.select(obj.primaryKey,name,varargin);
        end
    end
    function out=set(obj,name,fld,val)
        name=obj.parse_name(name);
        obj.useTable(obj.tableName);
        obj.parse_flags_for_set(name,fld);
        obj.update(obj.PrimaryKey,name,fld,val);
    end
    function out=rm(obj,name)
        name=obj.parse_name(name);

        obj.useTable(obj.tableName);
        obj.parse_flags_for_set(name,fld);

        obj.mms.delete(obj.PrimaryKey,name);
    end
    function out=rename_alias(obj,name,alias,newalias)
        if ~obj.bAlias; error('Aliases not configured for this database'); end
        name=obj.parse_name(name);

        obj.useTable(obj.tableName);
        obj.parse_flags_for_set(name,fld);

        obj.useTable(obj.aliasName);
        obj.mms.update(obj.PrimaryKey,name,'alias',alias,'alias',newalias);
    end
    function out=rename_alias_names(obj,name,newname)
        if ~obj.bAlias; error('Aliases not configured for this database'); end
        name=obj.parse_name(name);

        obj.useTable(obj.tableName);
        obj.parse_flags_for_set(name,fld);

        obj.useTable(obj.aliasName);
        obj.mms.update(obj.PrimaryKey,name,obj.PrimaryKey,newname);
    end
    function out=rm_alias(obj,name,alias,varargin)
        if ~obj.bAlias; error('Aliases not configured for this database'); end
        obj.mms.useTable(obj.aliasName);
        obj.parse_alias_entry(alias,varargin);
        obj.Entry.delete(obj.PrimaryKey,name,'alias',alias,varargin{:}); % XXX finish parse_crit
    end
    function out=add_alias(obj,name,alias)
        if ~obj.bAlias; error('Aliases not configured for this database'); end
        obj.mms.useTable(obj.aliasName);
        obj.parse_alias_entry(alias,varargin);
        obj.Entry.add(obj.PrimaryKey,name,'alias',alias,varargin{;});
    end
    function out=get_alias(obj,name)
        if ~obj.bAlias; error('Aliases not configured for this database'); end
        obj.useTable(obj.aliasName);
        out=obj.mms.Entry.select(obj.primaryKey,name,'alias');
    end
    function parse_flags_for_set(name,fld)
        out=obj.get(name,'updating','completion','archived');
        STR='';
        if bLocked
            STR=[STR ' locked,'];
        end
        if bArchived
            STR=[STR ' archived,'];
        end
        if bUpdating==0
            STR=[STR ' not flagged for updating,'];
        end
        if isempty(STR)
            return
        else
            error('Entry is' STR(1:end-1));
        end

    end
    function out=flag(obj,name,fld)
        name=obj.parse_name(name);
        out=obj.get(name,fld);
        if out==0
            obj.useTable(obj.tableName);
            obj.update(obj.PrimaryKey,name,fld,0);
        else
            error('Entry was not already flagged as %s.',fld); %
        end
    end
    function out=unflag(obj,name,fld)
        name=obj.parse_name(name);
        out=obj.get(name,fld);
        if out==1
            obj.update(obj.PrimaryKey,name,fld,0);
        else
            error('Entry was not already unflagged as %s.',fld); %
        end
    end
end
end
