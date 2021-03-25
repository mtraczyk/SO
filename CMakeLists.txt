project(diakrytynizator)

cmake_minimum_required(VERSION 3.17)

enable_language(C ASM_NASM)

set(CMAKE_ASM_NASM_FLAGS_DEBUG "-g -Fdwarf")

set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")

# Create a compile option that operates on ASM_NASM files
# If the target has a property NASM_OBJ_FORMAT, use it, otherwise
# use the environment variable CMAKE_ASM_NASM_OBJECT_FORMAT
add_compile_options(
        "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJ_FORMAT>>, \
    $<TARGET_PROPERTY:NASM_OBJ_FORMAT>, ${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
)

add_executable(diakrytynizator diakrytynizator.asm diakrytynizator_c.c)

set_target_properties(diakrytynizator PROPERTIES NASM_OBJ_FORMAT elf64)