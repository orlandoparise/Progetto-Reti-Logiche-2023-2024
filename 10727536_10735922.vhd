{\rtf1\ansi\ansicpg1252\cocoartf2759
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 LIBRARY ieee;\
USE ieee.std_logic_1164.ALL;\
\
entity project_reti_logiche is\
    port (\
        i_clk   : in std_logic;\
        i_rst   : in std_logic;\
        i_start : in std_logic;\
        i_add   : in std_logic_vector(15 downto 0);\
        i_k     : in std_logic_vector(9 downto 0);\
        \
        o_done  : out std_logic;\
        \
        o_mem_addr  : out std_logic_vector(15 downto 0);\
        i_mem_data  : in std_logic_vector(7 downto 0);\
        o_mem_data  : out std_logic_vector(7 downto 0);\
        o_mem_we    : out std_logic;\
        o_mem_en    : out std_logic\
    );\
\
end project_reti_logiche;\
\
architecture behavioral of project_reti_logiche is\
    -- type stati is ();\
begin\
\
end behavioral;\
}