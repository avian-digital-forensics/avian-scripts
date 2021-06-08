module InappScriptUtils
    extend self

    # Returns the string placed between Avian| and |<tag_name> in tags from the specified script.
    def find_script_tag_prefix(script_name)
        script_name.split('_').map{|e| e.capitalize}.join
    end

    # Returns the given tag in script tag format, i.e. Avian|<script name>|<tag>.
    # If tag already has some of the prefix, this is not duplicated.
    def to_script_tag(script_name, tag)
        script_tag_prefix = InappScriptUtils::find_script_tag_prefix(script_name)
        if tag.start_with?('Avian|' + script_tag_prefix + '|')
            return tag
        elsif tag.start_with?('Avian|')
            return 'Avian|' + InappScriptUtils::find_script_tag_prefix(script_name) + '|' + tag[6..-1]
        elsif tag.start_with?(script_tag_prefix + '|')
            return 'Avian|' + tag
        else
            return 'Avian|' + script_tag_prefix + '|' + tag
        end
    end
end